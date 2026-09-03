# Generating And Analyzing BATTER Benchmark Files

The BATTER benchmark helper scripts now live in the `bat_mem` package as CLI tools.

Use the `batter` environment, where `bat_mem` has been installed editable:

```bash
conda activate batter
```

If the commands are not on `PATH`, reinstall the package:

```bash
python -m pip install -e /home/users/yuzhuang/oak/software/bat_mem
```

## CLI Tools

- `bat-benchmark-prepare`: generate BATTER benchmark input folders from FEP benchmark files.
- `bat-benchmark-analysis`: discover and run the standard ABFE and RBFE analyses from one BATTER system folder.
- `bat-benchmark-analysis-abfe`: run ABFE analysis directly.
- `bat-benchmark-analysis-rbfe`: run RBFE Cinnabar analysis directly.

Check options with:

```bash
bat-benchmark-prepare --help
bat-benchmark-analysis --help
bat-benchmark-analysis-abfe --help
bat-benchmark-analysis-rbfe --help
```

## Input Layout

For a standard benchmark set, `bat-benchmark-prepare` expects files named:

```text
fep_benchmark_inputs/structure_inputs/<set>/<system>_ligands.sdf
fep_benchmark_inputs/structure_inputs/<set>/<system>_protein.pdb
fep_benchmark_inputs/structure_inputs/<set>/<system>_edges.csv
```

The edge CSV is optional for file generation. The SDF should contain ligand records with names in `_Name`; experimental binding free energies are later read from the `r_exp_dg` property.

## Generate One System

Example for JACS TYK2:

```bash
bat-benchmark-prepare \
  --source-dir fep_benchmark_inputs/structure_inputs/jacs_set \
  --system-name tyk2 \
  --output-dir fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2
```

This creates:

```text
fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/
  INPUTS/
    <ligand>.sdf
    <ligand>.pdb
    tyk2_protein.pdb
  ligand_dict.json
  tyk2_ligands.sdf
  tyk2_protein.pdb
  tyk2_edges.csv
  mabfe.yaml
  rbfe.yaml
  rbfe_48.yaml
  rbfe_septop.yaml
```

`rbfe.yaml` uses the default 24-window RBFE lambda schedule. `rbfe_48.yaml` uses `RBFE_48_LAMBDAS`. `rbfe_septop.yaml` uses the `rbfe_septop` protocol with `RBFE_48_LAMBDAS` and writes to `<system>_septop_rbfe_48`.

## Anchor Atoms

Anchor atoms are optional. If no anchors are provided, generated YAML files omit the `anchor_atoms` block.

To include anchors, provide exactly three selections:

```bash
bat-benchmark-prepare \
  --source-dir fep_benchmark_inputs/structure_inputs/jacs_set \
  --system-name tyk2 \
  --output-dir fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2 \
  --anchor-atom "name CA and resid 1041" \
  --anchor-atom "name CA and resid 910" \
  --anchor-atom "name CA and resid 914"
```

For batch generation, anchors can be provided through a CSV:

```csv
system_name,anchor_atom1,anchor_atom2,anchor_atom3
tyk2,name CA and resid 1041,name CA and resid 910,name CA and resid 914
```

Then run:

```bash
bat-benchmark-prepare \
  --source-dir fep_benchmark_inputs/structure_inputs/jacs_set \
  --system-name tyk2 \
  --output-dir fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2 \
  --anchor-file anchors.csv
```

## Generate All Systems In A Set

To generate BATTER folders for every `*_ligands.sdf` in a benchmark set:

```bash
bat-benchmark-prepare \
  --source-dir fep_benchmark_inputs/structure_inputs/jacs_set \
  --output-root fep_benchmark_inputs/structure_inputs/batter_run \
  --all
```

This writes one output folder per system using this pattern:

```text
fep_benchmark_inputs/structure_inputs/batter_run/<set>_<system>/
```

If using `--all` with anchors, pass `--anchor-file`; systems without a matching row will still be generated without `anchor_atoms`.

For all systems under `fep_benchmark_inputs/structure_inputs/`, use:

```bash
fep_benchmark_inputs/structure_inputs/prepare_all_structure_inputs_new_batter_run.sh
```

This runs commands like:

```bash
bat-benchmark-prepare \
  --source-dir fep_benchmark_inputs/structure_inputs/scaffold_hopping \
  --system-name Era_2q70 \
  --output-dir fep_benchmark_inputs/structure_inputs/new_batter_run/Era_2q70
```

The script skips generated folders such as `batter/`, `batter_run/`, and `new_batter_run/`. If a system name appears in more than one source set, the output folder is prefixed with the set name, for example `new_batter_run/jacs_set_tyk2` and `new_batter_run/charge_annhil_tyk2`.

## Explicit Input Paths

If files do not follow the `<system>_*.sdf/pdb/csv` naming convention, provide paths directly:

```bash
bat-benchmark-prepare \
  --system-name my_system \
  --sdf-file path/to/ligands.sdf \
  --pdb-file path/to/protein.pdb \
  --csv-file path/to/edges.csv \
  --output-dir fep_benchmark_inputs/structure_inputs/batter_run/my_system
```

## Customize Generated YAML

Common options:

```bash
--atom-mapper lomap
--no-both-directions
--n-steps 500000
--eq-steps 0
--analysis-start-step 100000
--run-id rep1
--max-workers 8
--max-active-jobs 200
--partition rondror,owners
--time 4:00:00
--email you@example.edu
```

The output YAML filenames can also be changed:

```bash
--abfe-yaml mabfe.yaml
--rbfe-yaml rbfe.yaml
--rbfe-48-yaml rbfe_48.yaml
--rbfe-septop-yaml rbfe_septop.yaml
```

## Run BATTER

After generation, run BATTER from the output folder:

```bash
cd fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2
batter run rbfe.yaml
batter run rbfe_48.yaml
batter run rbfe_septop.yaml
batter run mabfe.yaml
```

BATTER execution directories named `executions/` are ignored by Git.

## Analyze Results

Run the combined analysis from one BATTER system folder:

```bash
bat-benchmark-analysis \
  --input fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2
```

The combined analysis discovers:

- the experimental `*_ligands.sdf` file
- ABFE result folders matching `*_abfe/results/index.csv`
- RBFE Cinnabar folders matching `*_rbfe/results/cinnabar/.../cinnabar_relative.csv` and `cinnabar_absolute.csv`

It runs whichever analyses are discoverable, so ABFE-only and RBFE-only folders work without extra flags.

Default outputs are written under the input folder:

```text
abfe_analysis/
rbfe_cinnabar_analysis/
replicate_performance.csv
replicate_performance_deviation.csv
analysis_manifest.json
```

Scatter plots include the number of data points, number of replicates, and error/correlation statistics. `replicate_performance.csv` reports one row per ABFE run ID and one row per discovered RBFE Cinnabar replicate/mode/plot, including each replicate's deviation from the group mean. `replicate_performance_deviation.csv` summarizes the replicate means and sample standard deviations for each metric. Structure reports are written as both PDF and HTML. The HTML reports are usually easier to inspect in remote VSCode sessions.

To run the scripts directly:

```bash
bat-benchmark-analysis-rbfe \
  --cinnabar-dir fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/tyk2_rbfe/results/cinnabar/rep1 \
  --exp-sdf fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/tyk2_ligands.sdf \
  --output-dir fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/rbfe_cinnabar_analysis \
  --target-name TYK2

bat-benchmark-analysis-abfe \
  --abfe-results fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/tyk2_abfe \
  --exp-sdf fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/tyk2_ligands.sdf \
  --output-dir fep_benchmark_inputs/structure_inputs/batter_run/jacs_set_tyk2/abfe_analysis \
  --target-name TYK2
```
