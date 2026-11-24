# Olala mini (OVHcloud) — serveur compatible OpenAI, sur processeur
# Construit la version modifiée de llama.cpp d'OVHcloud (architecture « olala »).

# ---------- Étape 1 : compilation ----------
FROM debian:bookworm-slim AS build
ARG LLAMA_REPO=https://github.com/OVHai-LLM/llama.cpp.git
ARG LLAMA_REF=main
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "${LLAMA_REF}" "${LLAMA_REPO}" /src \
    && git -C /src rev-parse --short HEAD > /src/COMMIT
WORKDIR /src
# Image portable : instructions AVX2/FMA (tous les Ryzen et Intel depuis ~2015).
# GGML_NATIVE=OFF, sinon le binaire serait optimisé pour le processeur de GitHub
# et pourrait planter (« illegal instruction ») sur ton serveur.
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release \
        -DGGML_NATIVE=OFF -DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_FMA=ON -DGGML_F16C=ON \
        -DBUILD_SHARED_LIBS=OFF -DLLAMA_CURL=OFF -DLLAMA_USE_PREBUILT_UI=OFF \
        -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
    && cmake --build build -j"$(nproc)" --target llama-server

# ---------- Étape 2 : image finale ----------
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgomp1 ca-certificates curl tini \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/build/bin/llama-server /app/llama-server
COPY --from=build /src/COMMIT /app/LLAMA_COMMIT
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Réglages par défaut (modifiables dans le modèle Unraid)
ENV MODEL_FILE=Olala-v1.0-mini-7A1B-q8_0-safe2.gguf \
    MODEL_REPO=OVHaiLLM/Olala-v1.0-mini-7A1B-GGUF \
    MODEL_ALIAS=olala-mini \
    THREADS=5 \
    CTX_SIZE=32768 \
    PARALLEL=2 \
    REASONING_EFFORT=low \
    API_KEY="" \
    EXTRA_ARGS=""

VOLUME ["/models"]
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=600s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
