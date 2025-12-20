import subprocess
import re
import gzip
import argparse
import zipfile
import json
import os

# This script computes the Figure of Merit (FOM) for a given ASIC design.
# use 'python scripts/fom.py' from the repo directory to run the script

def compute_fom(f_max, cycles, area):
    return 1e10 * (f_max / (cycles * area**0.5))

def get_fmax(gz_path="build/par-rundir/timingReports/riscv_top_postRoute_all.tarpt.gz"):
    try:
        # run make par
        # print("Running make par...")
        # cmd = ["make", "par"]    
        # result = subprocess.run(cmd, check=True)

        # Open and read the gzipped report
        with gzip.open(gz_path, 'rt') as f:
            lines = f.readlines()

        slack = None
        required_time = None

        # Search for Slack and Required Time lines
        for line in lines:
            if "Slack:=" in line:
                match = re.search(r"Slack:=[\s]+([-\d.]+)", line)
                if match:
                    slack = float(match.group(1))
            if "Required Time:=" in line:
                match = re.search(r"Required Time:=[\s]+([-\d.]+)", line)
                if match:
                    required_time = float(match.group(1))
            if slack is not None and required_time is not None:
                break

        if slack is None or required_time is None:
            raise ValueError("Could not find both Slack and Required Time in the report.")

        # Frequency in GHz = 1 / (period in ns)
        period_ns = required_time - slack
        if period_ns <= 0:
            raise ValueError(f"Invalid period: Required Time - Slack = {period_ns}")

        frequency_ghz = 1.0 / period_ns

        return {
            "required_time_ns": required_time,
            "slack_ns": slack,
            "frequency_ghz": frequency_ghz
        }

    except Exception as e:
        raise RuntimeError(f"Failed to process gzipped report: {e}")

def get_area(script_path="scripts/get_area.sh"):
    try:
        # Execute the bash script and capture output
        result = subprocess.run(["bash", script_path], capture_output=True, text=True, check=True)
        output = result.stdout

        # Find the section starting with @@file 6
        lines = output.splitlines()
        start_idx = next(i for i, line in enumerate(lines) if line.startswith('@@file 6'))

        # Search for the riscv_top line after that
        for line in lines[start_idx+1:]:
            # Skip dashed headers or blank lines
            if re.match(r'^-+$', line.strip()) or not line.strip():
                continue
            if 'riscv_top' in line:
                parts = line.strip().split()
                if len(parts) >= 2:
                    inst_count = int(parts[-2])
                    total_area = float(parts[-1])
                    return {"inst_count": inst_count, "total_area": total_area}
                else:
                    raise ValueError("Malformed line for riscv_top: " + line)
        raise ValueError("riscv_top entry not found after @@file 6")
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Script execution failed: {e.stderr}")
    except Exception as e:
        raise RuntimeError(f"Parsing failed: {e}")

def get_cycles(test_bmark="sum.out"):
    try:
        # Run make sim-rtl with the test_bmark argument
        cmd = ["make", "sim-rtl", "-B", f"test_bmark={test_bmark}"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        output = result.stdout

        # Look for the [ PASSED ] line with simulation cycles
        pattern = r"\[ PASSED \]\s+.+? after ([\d_]+) simulation cycles"
        match = re.search(pattern, output)
        if match:
            sim_cycles_str = match.group(1).replace("_", "")  # remove underscores if present
            sim_cycles = int(sim_cycles_str)
            return {
                "passed": True,
                "simulation_cycles": sim_cycles
            }
        else:
            return {
                "passed": False,
                "simulation_cycles": None
            }

    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Simulation failed:\n{e.stdout}\n{e.stderr}")

def dump_to_submission(fom, f_max, cycles, area, submission_path):
    res = {
            "score": 1.0,
            "output": f"Success! FOM: {fom}",
            "leaderboard": [
                {"name": "Frequency (MHz)", "value": f_max},
                {"name": "Area", "value": area, "order": "asc"},
                {"name": "Cycles", "value": cycles, "order": "asc"},
                {"name": "FOM", "value": fom},
            ]
        }

    # make temporary directory and write results.json
    os.makedirs(submission_path, exist_ok=True)

    json_path = os.path.join(submission_path, "results.json")
    zip_path = os.path.join(submission_path, "results.zip")

    with open(json_path, "w") as w:
        json.dump(res, w)

    # zip the file
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(json_path, arcname="results.json")

def main():
    parser = argparse.ArgumentParser(description="Compute Figure of Merit (FOM) for ASIC design.")
    parser.add_argument("--cycles", type=int, help="Number of cycles of sum simulation.", default=None)
    parser.add_argument('--submission_path', type=str, help='Path to output submission zip file.', default=".submission")

    args = parser.parse_args()

    ###### get cycles from simulation ######
    if args.cycles is not None:
        cycles = args.cycles
        print(f"Manually specified cycles: {cycles}")
    else:
        print("Running simulation...")
        cycles_data = get_cycles()
        if not cycles_data["passed"]:
            raise RuntimeError("Simulation did not pass successfully.")
        cycles = cycles_data["simulation_cycles"]
        print(f"Simulation cycles: {cycles}")

    ##### get frequency from timing report #####
    # TODO maybe invalidate negative slack?
    print("Getting frequency from timing report...")
    f_max_data = get_fmax()
    if f_max_data["slack_ns"] < 0:
        raise RuntimeError(f"Negative slack: {f_max_data['slack_ns']} ns")
    f_max = f_max_data["frequency_ghz"] * 1000
    print(f"Frequency: {f_max} MHz")

    ###### get area from innovus script ######
    print("Getting area from Innovus...")
    area_data = get_area()
    area = area_data["total_area"]
    print(f"Area: {area} um^2")

    fom = compute_fom(f_max, cycles, area)
    print(f"Figure of Merit (FOM); {fom}")

    dump_to_submission(fom, f_max, cycles, area, args.submission_path)

if __name__ == "__main__":
    main()