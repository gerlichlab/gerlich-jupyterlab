#!/usr/bin/env bash
# Usage: sbatch build.sbatch <file.def> <output.sif>
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G

export APPTAINER_CACHEDIR=$SCRATCHDIR/apptainer-cache
export APPTAINER_TMPDIR=$TMPDIR

apptainer build "$2" "$1"
