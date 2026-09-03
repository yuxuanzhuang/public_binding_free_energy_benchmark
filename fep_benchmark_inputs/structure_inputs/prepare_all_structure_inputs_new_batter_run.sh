#!/usr/bin/env bash
set -euo pipefail

STRUCTURE_INPUTS_DIR="${STRUCTURE_INPUTS_DIR:-fep_benchmark_inputs/structure_inputs}"
OUTPUT_ROOT="${OUTPUT_ROOT:-fep_benchmark_inputs/structure_inputs/new_batter_run}"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${repo_root}"

if ! command -v bat-benchmark-prepare >/dev/null 2>&1; then
  echo "Error: bat-benchmark-prepare is not on PATH. Activate the batter environment first." >&2
  exit 127
fi

mapfile -t ligand_sdfs < <(
  find "${STRUCTURE_INPUTS_DIR}" \
    -path "${STRUCTURE_INPUTS_DIR}/batter" -prune -o \
    -path "${STRUCTURE_INPUTS_DIR}/batter_run" -prune -o \
    -path "${STRUCTURE_INPUTS_DIR}/new_batter_run" -prune -o \
    -name '*_ligands.sdf' \
    -type f \
    -print | sort
)

if [[ ${#ligand_sdfs[@]} -eq 0 ]]; then
  echo "Error: no *_ligands.sdf files found under ${STRUCTURE_INPUTS_DIR}" >&2
  exit 1
fi

declare -A system_counts=()
for ligand_sdf in "${ligand_sdfs[@]}"; do
  filename="$(basename "${ligand_sdf}")"
  system_name="${filename%_ligands.sdf}"
  current_count="${system_counts[${system_name}]:-0}"
  system_counts["${system_name}"]=$((current_count + 1))
done

mkdir -p "${OUTPUT_ROOT}"

for ligand_sdf in "${ligand_sdfs[@]}"; do
  source_dir="$(dirname "${ligand_sdf}")"
  filename="$(basename "${ligand_sdf}")"
  system_name="${filename%_ligands.sdf}"
  output_name="${system_name}"

  if [[ "${system_counts[${system_name}]}" -gt 1 ]]; then
    source_label="${source_dir#${STRUCTURE_INPUTS_DIR}/}"
    source_label="${source_label//\//_}"
    output_name="${source_label}_${system_name}"
  fi

  echo "Preparing ${source_dir}/${system_name} -> ${OUTPUT_ROOT}/${output_name}"
  bat-benchmark-prepare \
    --source-dir "${source_dir}" \
    --system-name "${system_name}" \
    --output-dir "${OUTPUT_ROOT}/${output_name}" \
    "$@"
done
