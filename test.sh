#!/bin/bash
set -euo pipefail

INPUT_DIR="tests/input"
EXPECTED_DIR="tests/expected"
LOG_DIR="tests/logs"
OUT_DIR="tests/out"
PROGRAM="./schedule_processes"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# run test.sh -g to generate expected outputs
GENERATE=0
if [[ "${1-}" == "--generate" || "${1-}" == "-g" ]]; then
    GENERATE=1
    echo -e "${GREEN} GENERATE MODE ENABLED${NC}"
    echo " Output files will be saved to $EXPECTED_DIR"
fi

mkdir -p "$LOG_DIR" "$OUT_DIR" "$EXPECTED_DIR"

if [ ! -f "$PROGRAM" ] || [ ! -x "$PROGRAM" ]; then
    echo -e "${RED}Error: Executable $PROGRAM not found or is not executable.${NC}"
    exit 1
fi

PASSED=0
FAILED=0
TOTAL=0
HAS_ERROR=0

# Schedulers: 0 (Priority), 1 (Round Robin), 2 (FCFS)
SCHEDULERS=(0 1 2)
SCHED_NAMES=("Priority" "Round Robin" "FCFS")

# Delete previous thr0.log and thr0.out files
rm -f thr0.log thr0.out

# Check if input exists
shopt -s nullglob
INPUT_FILES=("$INPUT_DIR"/*.list)
if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    echo "No test cases found in $INPUT_DIR."
    exit 0
fi

for input_file in "${INPUT_FILES[@]}"; do
    filename=$(basename -- "$input_file")
    testname="${filename%.*}"

    for i in "${!SCHEDULERS[@]}"; do
        sched="${SCHEDULERS[$i]}"
        sched_name="${SCHED_NAMES[$i]}"

        # Run program and capture stdout/stderr
        "$PROGRAM" 1 "$input_file" "$sched" 2> "$OUT_DIR/${sched}_${testname}.stderr" > "$OUT_DIR/${sched}_${testname}.stdout" || true

        # Check output files
        if [ ! -f "thr0.log" ] || [ ! -f "thr0.out" ]; then
            printf "${RED}[FAIL]${NC} | %-20s \t [%s] (Missing thr0.log/out)\n" "$testname" "$sched_name"
            ((FAILED++))
            ((TOTAL++))
            HAS_ERROR=1
            continue
        fi

        if [ $GENERATE -eq 1 ]; then
            mv thr0.log "$EXPECTED_DIR/${sched}_${testname}.log.exp"
            mv thr0.out "$EXPECTED_DIR/${sched}_${testname}.out.exp"
            printf "${GREEN}[GEN ]${NC} | %-20s \t [%s]\n" "$testname" "$sched_name"
        else
            mv thr0.log "$LOG_DIR/${sched}_${testname}.log"
            mv thr0.out "$OUT_DIR/${sched}_${testname}.out"

            expected_log="$EXPECTED_DIR/${sched}_${testname}.log.exp"

            if [ ! -f "$expected_log" ]; then
                printf "${RED}[FAIL]${NC} | %-20s \t [%s] (Missing expected log)\n" "$testname" "$sched_name"
                ((FAILED++))
                HAS_ERROR=1
            else
                diff_file="$LOG_DIR/${sched}_${testname}.diff"
                diff -u "$expected_log" "$LOG_DIR/${sched}_${testname}.log" > "$diff_file" || HAS_ERROR=1

                if [ $HAS_ERROR -eq 0 ]; then
                    printf "${GREEN}[PASS]${NC} | %-20s \t [%s]\n" "$testname" "$sched_name"
                    ((PASSED++))
                    rm -f "$diff_file"
                else
                    printf "${RED}[FAIL]${NC} | %-20s \t [%s] (See %s)\n" "$testname" "$sched_name" "$diff_file"
                    ((FAILED++))
                fi
            fi
        fi
        ((TOTAL++))
    done
done

echo "--------------------------------------------------"

if [ $GENERATE -eq 1 ]; then
    echo -e "${GREEN}Generation complete. $TOTAL expected outputs updated.${NC}"
    exit 0
fi

echo "Test Run Summary: $PASSED passed, $FAILED failed, $TOTAL total."

if [ $HAS_ERROR -ne 0 ]; then
    exit 1
else
    exit 0
fi
