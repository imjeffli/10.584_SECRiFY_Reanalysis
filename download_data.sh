#!/bin/bash

# Job Flags
#SBATCH -p mit_normal
#SBATCH -c 1
#SBATCH -t 12:00:00
#SBATCH --mem-per-cpu=1000
#SBATCH --array=0-11

set -euo pipefail

runs_per_job=1
array_jobs=12
submit_dir="${SLURM_SUBMIT_DIR:-$PWD}"
runs_tsv="${1:-$submit_dir/runs.tsv}"
raw_dir="$submit_dir/raw"
task_id="${SLURM_ARRAY_TASK_ID:?Submit this script with sbatch so SLURM_ARRAY_TASK_ID is set}"

if [[ ! -f "$runs_tsv" ]]; then
    echo "ERROR: runs table not found: $runs_tsv" >&2
    exit 1
fi

if (( task_id < 0 || task_id >= array_jobs )); then
    echo "ERROR: array task ID must be between 0 and $((array_jobs - 1)); got $task_id" >&2
    exit 1
fi

run_count=$(awk 'END { print NR - 1 }' "$runs_tsv")
expected_runs=$((runs_per_job * array_jobs))
if (( run_count != expected_runs )); then
    echo "ERROR: expected $expected_runs data rows in $runs_tsv, found $run_count" >&2
    exit 1
fi

mkdir -p "$raw_dir"

first_data_row=$((task_id * runs_per_job + 2))
last_data_row=$((first_data_row + runs_per_job - 1))

echo "Array task $task_id: downloading TSV rows $first_data_row-$last_data_row into $raw_dir"

while IFS=$'\t' read -r accession; do
    [[ -n "$accession" ]] || {
        echo "ERROR: missing accession in rows $first_data_row-$last_data_row" >&2
        exit 1
    }

    for accession in "${accession[@]}"; do
        echo "Processing $accession"
        sbatch 
    done
done < <(
    awk -F'\t' -v first="$first_data_row" -v last="$last_data_row" \
        'NR >= first && NR <= last { print $1 }' "$runs_tsv"
)
