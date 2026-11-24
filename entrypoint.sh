#!/bin/sh
# Démarrage du serveur Olala : télécharge le modèle au premier lancement, puis lance llama-server.
set -eu

MODEL_PATH="/models/${MODEL_FILE}"
MODEL_URL="https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}"

echo "=== Olala mini — llama.cpp OVHcloud (commit $(cat /app/LLAMA_COMMIT)) ==="

if [ ! -s "$MODEL_PATH" ]; then
    echo "Modèle absent : téléchargement de ${MODEL_FILE} (plusieurs Go, une seule fois)…"
    echo "Source : ${MODEL_URL}"
    # -C - : reprend un téléchargement interrompu
    curl -fL --retry 5 --retry-delay 10 -C - -o "${MODEL_PATH}.part" "$MODEL_URL"
    mv "${MODEL_PATH}.part" "$MODEL_PATH"
    echo "Téléchargement terminé."
else
    echo "Modèle trouvé : ${MODEL_PATH}"
fi

set -- /app/llama-server \
    -m "$MODEL_PATH" \
    --alias "$MODEL_ALIAS" \
    --host 0.0.0.0 --port 8080 \
    -t "$THREADS" -c "$CTX_SIZE" -np "$PARALLEL" \
    -fa on -nr -ctk q8_0 -ctv q8_0 \
    --temp 0.8 --top-p 0.9 --top-k 40 \
    --jinja --reasoning-effort "$REASONING_EFFORT"

if [ -n "${API_KEY}" ]; then
    set -- "$@" --api-key "$API_KEY"
fi

# Options supplémentaires libres (ex. : --metrics)
# shellcheck disable=SC2086
[ -n "${EXTRA_ARGS}" ] && set -- "$@" ${EXTRA_ARGS}

echo "Lancement : threads=${THREADS} contexte=${CTX_SIZE} conversations=${PARALLEL} alias=${MODEL_ALIAS}"
exec "$@"
