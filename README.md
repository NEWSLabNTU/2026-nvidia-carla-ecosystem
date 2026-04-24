# 2026-nvidia-carla-ecosystem
Exploring various NVIDIA technologies that have been integrated into CARLA.

## NuRec
### Installation

1. Docker Group & NVIDIA Container Toolkit & Docker Runtime configured.
2. Install [CARLA 0.9.16](https://github.com/carla-simulator/carla/releases/tag/0.9.16/).
3. Copy [`install_nurec_without_sudo.sh`](NuRec/install_nurec_without_sudo.sh) to `<CARLA_ROOT>/PythonAPI/examples/nvidia/nurec/`.
4. Copy [`.envrc`](.envrc) and [`justfile`](justfile) to `<CARLA_ROOT>`.
5. HuggingFace account and a token with read permissions.
   - The installation script will download the [NVIDIA NuRec Dataset](https://huggingface.co/datasets/nvidia/PhysicalAI-Autonomous-Vehicles-NuRec) (release `25.07`) from HuggingFace, you must have a Hugging Face account and create a token
      - If you don't already have a Hugging Face account, create one and log in
      - Find the dataset on the Hugging face website with the above link
      - Click on ✔ Agree and access repository
      - Create a token with Read permissions
      - Save the token in a safe place and enter it when prompted during the installation
   - ⚠️ The dataset is over 1.5TB in size so ensure that you have adequate hard drive space
6. Run the installation script.
   ```bash
   cd <CARLA_ROOT>
   just install-nurec
   ```
7. Start simulation
   ```bash
   # terminal 1
   just carla
   
   # terminal 2
   just nurec-replay
   ```

## SimReady

- [Import assets from Omniverse to CARLA](https://carla.readthedocs.io/en/0.9.16/ecosys_simready)
   - ⚠️ Documentation is outdated since NVIDIA Omniverse Launcher is deprecated on October 1st, 2025.
   - ⚠️ Require Unreal Engine + Carla ([build from source](https://carla.readthedocs.io/en/0.9.16/build_linux/)).
- [Import assets from CARLA to Omniverse](https://carla.readthedocs.io/en/0.9.16/nvidia_simready/)


## Cosmos Transfer

- A cluster with at least 8 x H100 GPUs is recommended.
   - A single H100 GPU should be enough for lower workloads.
- [Documentation](https://carla.readthedocs.io/en/latest/nvidia_cosmos_transfer/)

