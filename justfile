set shell := ["bash", "-c"]

# List all available commands
default:
	@just --list

# Start the CARLA Server
carla:
	@echo "🚀 Starting CARLA Server..."
	./CarlaUE4.sh -quality-level=Low

# Run all system and environment checks, then execute the NuRec installation
install-nurec: system-check _run-install

# Run all system and environment checks
system-check: _check-os _check-python _check-cuda _check-docker _check-nvidia-ctk _check-pip

_check-os:
	@echo "🔍 Checking OS..."
	@if [ -f /etc/os-release ]; then \
		source /etc/os-release; \
		if [ "$VERSION_ID" != "22.04" ]; then \
			echo "⚠️  Warning: Expected Ubuntu 22.04, found $PRETTY_NAME. Proceeding anyway..."; \
		else \
			echo "✅ OS is $PRETTY_NAME"; \
		fi; \
	else \
		echo "⚠️  Warning: Could not determine OS."; \
	fi

_check-python:
	@echo "🔍 Checking Python..."
	@python3 -c "import sys; exit(0) if sys.version_info >= (3, 10) else exit(1)" || \
		(echo "❌ Error: Python 3.10+ required. Found $(python3 --version)" && exit 1)
	@echo "✅ $(python3 --version) detected."

_check-cuda:
	@echo "🔍 Checking CUDA..."
	@if command -v nvidia-smi >/dev/null 2>&1; then \
		CUDA_VER=$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+'); \
		MAJOR=$(echo $CUDA_VER | cut -d. -f1); \
		MINOR=$(echo $CUDA_VER | cut -d. -f2); \
		if [ "$MAJOR" -lt 12 ] || ([ "$MAJOR" -eq 12 ] && [ "$MINOR" -lt 8 ]); then \
			echo "❌ Error: CUDA 12.8+ required. Found $CUDA_VER."; exit 1; \
		else \
			echo "✅ CUDA $CUDA_VER detected."; \
		fi \
	else \
		echo "❌ Error: nvidia-smi not found. Check NVIDIA drivers."; exit 1; \
	fi

_check-docker:
	@echo "🔍 Checking Docker..."
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "❌ Error: Docker is not installed. Please install Docker first."; exit 1; \
	fi
	@if ! docker ps > /dev/null 2>&1; then \
		echo "❌ Error: Cannot connect to Docker. Verify you are in the 'docker' group or that the Docker daemon is running."; exit 1; \
	else \
		echo "✅ Docker access confirmed."; \
	fi

_check-nvidia-ctk:
	@echo "🔍 Checking NVIDIA Container Toolkit..."
	@if ! command -v nvidia-ctk >/dev/null 2>&1; then \
		echo "❌ Error: NVIDIA Container Toolkit is not installed. Please install it first."; exit 1; \
	else \
		echo "✅ NVIDIA Container Toolkit is already installed."; \
	fi

_check-pip:
	@echo "🔍 Checking pip..."
	@if ! command -v pip >/dev/null 2>&1; then \
		echo "❌ Error: pip is not installed. Please install it first."; exit 1; \
	else \
		echo "✅ pip is installed."; \
	fi


_run-install:
	@echo "🚀 All checks passed! Starting NuRec installation..."
	@cd PythonAPI/examples/nvidia/nurec && ./install_nurec_without_sudo.sh


# Replay a NuRec Scenario
nurec-replay:
	@echo "▶️ Replaying a NuRec Scenario..."
	# @cd PythonAPI/examples/nvidia/nurec && python example_nurec_replay_save_images.py --usdz-filename PhysicalAI-Autonomous-Vehicles-NuRec/sample_set/26.02_release/0a18c5a4-9aca-4efd-b604-c75f3269c502/0a18c5a4-9aca-4efd-b604-c75f3269c502.usdz --move-spectator
	@cd PythonAPI/examples/nvidia/nurec && python example_nurec_replay_save_images.py --usdz-filename PhysicalAI-Autonomous-Vehicles-NuRec/sample_set/25.07_release/Batch0001/026d6a39-bd8f-4175-bc61-fe50ed0403a3/026d6a39-bd8f-4175-bc61-fe50ed0403a3.usdz --move-spectator
