# Custom JupyterLab for CBE.next

This is the Gerlich lab's JupyterLab for OpenOnDemand on CBE.next. It comes with
Jupyter AI and Claude Code, working interactive widgets,
and our shared lab environment.

## Start JupyterLab

First, set up the app. You only need to do this once. It's a sandbox app from the HPC
team, and you don't need a GitHub account to get it:

```bash
mkdir -p ~/ondemand/dev && cd ~/ondemand/dev
git clone https://github.com/CLIP-HPC/ood_custom_jupyter_image.git custom-jupyter-image
```

Then reload the OpenOnDemand portal and go to **Develop** (the `</>` icon) >
**My Sandbox Apps (Development)** > **Jupyter (custom image)**. In the form, fill in:

- **Container image:** the newest `gerlich-jupyterlab-<date>.sif` from
  `/groups/gerlich/labinfo/Methods/singularity_images/`.
- **Root directory:** the folder JupyterLab opens in. If you leave it empty, that's
  your home.
- Partition, cores, memory, and hours, as you'd set them anywhere else. A session can
  run for up to 12 hours.

For your notebooks, pick the "Python (gerlich)" kernel. It has all the lab packages.
The "Python 3" kernel is just JupyterLab's own Python, without them.

GPUs haven't been tested yet, and the image doesn't include GPU packages.

## Use Claude in Jupyter AI

Before your first chat, log in to Claude once: run `claude` in a terminal, either on
CBE.next or in JupyterLab, and follow the steps. The login is saved in your home
directory, and JupyterLab picks it up from there. You can also use `claude` in a
JupyterLab terminal any time, just like on the cluster.

Chats are `.chat` files, which you save and name just like notebooks. Create a new
chat from the Launcher, with **File > New > Chat**, or with `Ctrl+Shift+C`. It's then
saved in the folder you have open in the file browser, right next to your project.
The **+** in the chat sidebar always puts new chats in your home directory.

**For now:** Claude only answers in chats saved directly in your home directory.
Chats in subfolders get stuck at "loading personas", because of an issue with
OpenOnDemand. Until it's fixed, create your chats with the **+** in the chat sidebar.

A new chat opens in the main area, like a notebook. If you'd like it next to your
notebook instead, drag its tab to the side, or right-click the tab and choose
**Move Widget To > Move To Right Sidebar**.

To talk to Claude, pick it in the menu in the chat's input bar, or write `@Claude`.
A few things that help:

- Claude can read and write files, run commands, and work with your notebooks. It
  always asks before it writes a file or runs a command.
- You don't need to attach your notebooks: Claude already sees the ones you have open,
  and it can find other files when you mention them by name. To point it at a
  specific file, you can still drag it into the chat, use the paperclip, or type
  `@file:` and pick it from the list.
- Save your notebook before you ask Claude to change it. JupyterLab won't reload a
  notebook that has unsaved changes, so you wouldn't see Claude's edits.

## Command-line tools

The command-line tools in the lab environment work outside JupyterLab too, for example
in your Slurm jobs. Here's an sbatch script that runs one tool:

```bash
#!/usr/bin/env bash
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

apptainer exec gerlich-jupyterlab-<date>.sif conda run -s -n gerlich cooler info file.cool
```

Don't forget the `-s`. Without it, pipes and live output won't work.

To run several commands in one go:

```bash
apptainer exec gerlich-jupyterlab-<date>.sif bash <<'EOF'
set -e
source /opt/conda/bin/activate gerlich
cooler info file.cool
pairtools sort in.pairs.gz -o out.pairs.gz
EOF
```

With `<<'EOF'` (with the quotes), the commands only see exported variables, like
`$SLURM_CPUS_PER_TASK`. To use variables you set earlier in your script, write `<<EOF`
without the quotes.

You don't need `--bind` for your data: the container sees `/groups`, `/scratch`, and
`/resources` at their usual paths. On GPU nodes, add `--nv`.

In notebooks with the "Python (gerlich)" kernel, you can use the tools right in a
cell, like `!cooler --help`, or in a `%%bash` cell.

JupyterLab terminals load your `.bashrc`, so your own conda and environments work as
usual there. Your conda doesn't know the image's environments, so activate the lab
environment with `source /opt/conda/bin/activate gerlich` instead of `conda activate`.

## Your own environments

You can use your own conda environments as kernels too. Install `ipykernel` into the
environment and register it once, as the
[OpenOnDemand docs](https://docs.vbc.ac.at/research-computing/cbe/openondemand-web-applications/)
describe under "Add a custom Jupyter kernel":

```bash
conda install -n my-env ipykernel
conda run -n my-env python -m ipykernel install --user --name my-env --display-name "Python (my-env)"
```

Next time you start JupyterLab, "Python (my-env)" shows up next to "Python (gerlich)".
The [Python and conda docs](https://docs.vbc.ac.at/research-computing/cbe/python-and-conda/)
have more on setting up environments.

To use your environment's command-line tools with `!` or `%%bash` in a notebook, run
this in the first cell:

```python
import os, sys; os.environ["PATH"] = os.path.dirname(sys.executable) + ":" + os.environ["PATH"]
```

If you use interactive widgets, install the same widget versions as the image (see
[Widget versions](#widget-versions)).

## Build and maintain the images

### How it's built

There are two images, one built on top of the other:

- `jupyterlab.sif` (from `jupyterlab.def` and `jupyterlab.yml`) has JupyterLab and its
  extensions.
- `gerlich.sif` (from `gerlich.def` and `gerlich.yml`) is `jupyterlab.sif` plus the
  `gerlich` conda environment, shown as the "Python (gerlich)" kernel. **This is the
  image people start.**

When you only change the lab environment, you only need to rebuild `gerlich.sif`.

Never put API keys or login files into an image.

### Build

Run these on CBE.next, in this folder:

```bash
sbatch build.sbatch jupyterlab.def jupyterlab.sif   # only when JupyterLab changes
sbatch build.sbatch gerlich.def gerlich.sif         # after jupyterlab.sif exists
```

Keep `jupyterlab.sif` in this folder, because `gerlich.def` builds on it. When
`gerlich.sif` is ready, copy it to
`/groups/gerlich/labinfo/Methods/singularity_images/gerlich-jupyterlab-<date>.sif`,
with the date written as `YYYY-MM-DD` (add `-2` if you build twice on the same day).
Give every build a new name, so people can keep using the older versions.

Then save the package lists of both images to git:

```bash
apptainer exec jupyterlab.sif cat /opt/jupyter/lock.txt > jupyterlab-lock.txt
apptainer exec gerlich.sif cat /opt/conda/envs/gerlich/lock.txt > gerlich-lock.txt
```

They record the exact version of every package. If you ever need an exact copy of an
environment, `conda create -p <path> --file gerlich-lock.txt` recreates it.

### Widget versions

Each widget package has a part in JupyterLab and a part in the kernel, and their
major.minor versions have to match: `ipywidgets=8.*`, `anywidget=0.11.*`,
`ipympl=0.10.*`. If you change one, change it in `jupyterlab.yml`, `gerlich.yml`, and
your own environments at the same time. When a widget shows "Error displaying widget",
a version mismatch is the usual reason.

### Images for papers

For a paper, `paper-template/paper.def` builds a single image with JupyterLab and the
paper's packages:

1. Copy `paper.def` and `paper.yml` from `paper-template/` into the paper's repo, and
   list the paper's packages with exact versions in `paper.yml`.
2. Build it, in the paper's repo: `sbatch <this repo>/build.sbatch paper.def <paper>-v1.sif`
3. Try it in the OpenOnDemand app, and save every notebook with the
   "Python (this image)" kernel selected.
4. Archive the `.sif` file next to the repo, for example on Zenodo.

Readers can then start it with `apptainer exec <paper>-v1.sif jupyter lab`. If they
want to see only the image's kernel, they add `--env JUPYTER_DATA_DIR=$(mktemp -d)`
right after `exec`.
