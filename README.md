# Docker compose homelab


## Useful scripts:

Watch GPU usage while testing Ollama models

    watch -n 1 nvidia-smi

Install more Ollama models

    docker exec -it ollama ollama pull qwen3:8b

## Deploy

    docker compose up -d

## Nginx proxy manager

😭 Sadly this is manual configured. I am using DuckDNS


