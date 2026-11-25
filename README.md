# Custom JupyterLab for CBE.next

Our JupyterLab for OpenOnDemand: Jupyter AI with Claude Code, the Material Darker
theme, widget support, and the shared lab environment.

## How it's built

There are two images, one on top of the other:

- `frontend.sif` (from `frontend.def` and `frontend.yml`): JupyterLab and extensions.
- `lab.sif` (from `lab.def` and `lab.yml`): `frontend.sif` plus the lab environment,
  shown as the "Lab env" kernel. **This is the image people start.**

Changing the lab env only rebuilds `lab.sif`. The frontend is reused as it is.

## Build

Run on CBE.next, in this folder:

```bash
sbatch build.sbatch frontend.def frontend.sif   # only when the frontend changes
sbatch build.sbatch lab.def lab.sif             # after frontend.sif exists
```

Keep `frontend.sif` here, because `lab.def` builds on it. Copy `lab.sif` to
`/groups/gerlich/labinfo/Methods/singularity_images/lab-<date>.sif`.
Use a new name each time, so old versions stay usable.

Save what's in each image to git:

```bash
apptainer exec frontend.sif cat /opt/jupyter/lock.txt > frontend-lock.txt
apptainer exec lab.sif cat /opt/lab-env/lock.txt > lab-lock.txt
```

These lists hold the exact version of every package. If you ever need an exact copy
of an environment, `conda create -p <path> --file lab-lock.txt` recreates it.

## Start JupyterLab

Start the custom JupyterLab app in OpenOnDemand and give it the path to `lab-<date>.sif`.
Pick the "Lab env" kernel for your notebooks. The "Python 3" kernel only has
JupyterLab itself in it, not the lab packages.

## Use Claude

Open the Jupyter AI chat in JupyterLab and write `@Claude`.

Log in once: run `claude` in a terminal on CBE.next and follow the login steps.
The login is saved in your home directory, and the image uses it from there.
Never put API keys or login files into an image.

Claude needs internet access from the compute node. If `@Claude` doesn't answer,
check that first.

## Your own environments

Build a conda or uv environment in your home or your own folder, install `ipykernel`
in it, activate it, and run:

```bash
python -m ipykernel install --user --name my-env
```

It shows up as a kernel next to "Lab env". Track the environment's files in git, so
you can rebuild it (see the cluster's Python guide).

Container kernels also work: see "Jupyter kernels" in the cluster's container docs.

## Images for papers

`paper-template/paper.def` builds one image with JupyterLab and the paper's packages:

1. Copy `paper.def` and `paper.yml` from `paper-template/` into the paper repo, and put
   the paper's packages with exact versions into `paper.yml`.
2. Build, in the paper repo: `sbatch <this repo>/build.sbatch paper.def <paper>-v1.sif`
3. Test it in the OOD app. Save every notebook with "Python (this image)" selected.
4. Archive the `.sif` file, for example on Zenodo, next to the repo.

Readers start it with `apptainer exec <paper>-v1.sif jupyter lab`. To see only the
image's kernel, add `--env JUPYTER_DATA_DIR=$(mktemp -d)` after `exec`.

## Widget versions

Interactive widgets have two parts: one in the frontend draws the widget, and one in
the kernel runs your code. The two must be compatible.

You don't need exact versions. The environment files allow any patch release
(`ipywidgets=8.*`, `anywidget=0.11.*`, `ipympl=0.10.*`). You only need to act when you
move one of these to a new major or minor version: change it in `frontend.yml`,
`lab.yml`, and your own environments at the same time.

If a widget shows "Error displaying widget" instead of a plot, a version mismatch
is the usual cause.
