# 2026-nvidia-carla-ecosystem
Exploring various NVIDIA technologies that have been integrated into CARLA.

## NuRec
### Installation
1. Install [CARLA 0.9.16](https://github.com/carla-simulator/carla/releases/tag/0.9.16/) or newer.
2. Copy [`install_nurec_without_sudo.sh`](NuRec/install_nurec_without_sudo.sh) to `<CARLA_ROOT>/PythonAPI/examples/nvidia/nurec/`.
3. Copy [`justfile`](justfile) to `<CARLA_ROOT>`.
4. Run installation scipt
   ```bash
   cd <CARLA_ROOT>
   just install-nurec
   ```
