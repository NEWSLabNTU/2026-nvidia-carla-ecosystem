# 2026-nvidia-carla-ecosystem
Exploring various NVIDIA technologies that have been integrated into CARLA.

## NuRec
### Installation


1. Install [CARLA 0.9.16](https://github.com/carla-simulator/carla/releases/tag/0.9.16/) or newer.
2. Copy [`install_nurec_without_sudo.sh`](NuRec/install_nurec_without_sudo.sh) to `<CARLA_ROOT>/PythonAPI/examples/nvidia/nurec/`.
3. Copy [`.envrc`](.envrc) and [`justfile`](justfile) to `<CARLA_ROOT>`.
4. HuggingFace account and a token with read permissions.
   - The installation script will download the [NVIDIA NuRec Dataset](https://huggingface.co/datasets/nvidia/PhysicalAI-Autonomous-Vehicles-NuRec) from HuggingFace, you must have a Hugging Face account and create a token
      - If you don't already have a Hugging Face account, create one and log in
      - Find the dataset on the Hugging face website with the above link
      - Click on ✔ Agree and access repository
      - Create a token with Read permissions
      - Save the token in a safe place and enter it when prompted during the installation
   - ⚠️ The dataset is over 1.7TB in size so ensure that you have adequate hard drive space
5. Run the installation script.
   ```bash
   cd <CARLA_ROOT>
   just install-nurec
   ```
