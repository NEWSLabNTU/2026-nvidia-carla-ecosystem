set shell := ["bash", "-c"]

# List all available commands
default:
	@just --list

# Run all system and environment checks, then execute the NuRec installation
install-nurec: _check-os _check-python _check-cuda _run-install

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

_run-install:
	@echo "🚀 All checks passed! Starting NuRec installation..."
	@cd PythonAPI/examples/nvidia/nurec && ./install_nurec_without_sudo.sh
