.DEFAULT_GOAL = install-models

# List of models to install
MODELS = qwen3:8b openhermes

# Optional: Add a help target to show usage
help:
	@echo "Usage:"
	@echo "  make install-models  # Install all models in the list"
	@echo "  make install-models MODEL=llama2  # Install a single model"

install-models:
		@for model in $(MODELS); do \
        echo "Installing model: $$model"; \
        docker exec -it ollama pull $$model; \
    done

monitor-gpu:
		watch -n1 nvidia-smi
