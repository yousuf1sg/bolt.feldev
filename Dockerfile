ARG BASE=node:20.18.0
FROM ${BASE} AS base
WORKDIR /app  
# Install pnpm using corepack (recommended approach)
#RUN corepack enable && corepack prepare pnpm@latest --activate
# Method 1: Install pnpm via npm (specific version)
RUN npm install -g pnpm@8

# Method 2: Or use curl to install
#RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm

# Create the script file with content
RUN echo "#!/bin/bash" > ./bindings.sh && \
    echo "echo 'Your script content here'" >> ./bindings.sh
    
# Set execute permissions for scripts
RUN chmod +x ./bindings.sh

# Verify permissions (optional debug step)
RUN ls -la ./bindings.sh && head -n 5 ./bindings.sh

# Debug: show current directory and contents
RUN pwd && ls -la
# Copy package.json first (for better layer caching)
FROM installer AS dependencies
WORKDIR /app
COPY package.json ./
COPY pnpm-lock.yaml ./

# Debug: show files were copied
RUN ls -la
#RUN npm install -g corepack@latest
#RUN corepack enable pnpm && pnpm install
#RUN npm install -g pnpm && pnpm install
RUN pnpm install --frozen-lockfile
# Copy the rest of your app's source code
FROM dependencies AS builder
WORKDIR /app
COPY . .

FROM dependencies AS builder
WORKDIR /app

# Expose the port the app runs on
EXPOSE 5173

# Production image
FROM base AS bolt-ai-production

# Define environment variables with default values or let them be overridden
ARG GROQ_API_KEY
ARG HuggingFace_API_KEY
ARG OPENAI_API_KEY
ARG ANTHROPIC_API_KEY
ARG OPEN_ROUTER_API_KEY
ARG GOOGLE_GENERATIVE_AI_API_KEY
ARG OLLAMA_API_BASE_URL
ARG XAI_API_KEY
ARG TOGETHER_API_KEY
ARG TOGETHER_API_BASE_URL
ARG AWS_BEDROCK_CONFIG
ARG VITE_LOG_LEVEL=debug
ARG DEFAULT_NUM_CTX

ENV WRANGLER_SEND_METRICS=false \
    GROQ_API_KEY=${GROQ_API_KEY} \
    HuggingFace_KEY=${HuggingFace_API_KEY} \
    OPENAI_API_KEY=${OPENAI_API_KEY} \
    ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
    OPEN_ROUTER_API_KEY=${OPEN_ROUTER_API_KEY} \
    GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY} \
    OLLAMA_API_BASE_URL=${OLLAMA_API_BASE_URL} \
    XAI_API_KEY=${XAI_API_KEY} \
    TOGETHER_API_KEY=${TOGETHER_API_KEY} \
    TOGETHER_API_BASE_URL=${TOGETHER_API_BASE_URL} \
    AWS_BEDROCK_CONFIG=${AWS_BEDROCK_CONFIG} \
    VITE_LOG_LEVEL=${VITE_LOG_LEVEL} \
    DEFAULT_NUM_CTX=${DEFAULT_NUM_CTX}\
    RUNNING_IN_DOCKER=true

# Pre-configure wrangler to disable metrics
RUN mkdir -p /root/.config/.wrangler && \
    echo '{"enabled":false}' > /root/.config/.wrangler/metrics.json

ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN pnpm run build

CMD [ "pnpm", "run", "dockerstart"]

# Development image
FROM base AS bolt-ai-development

# Define the same environment variables for development
ARG GROQ_API_KEY
ARG HuggingFace 
ARG OPENAI_API_KEY
ARG ANTHROPIC_API_KEY
ARG OPEN_ROUTER_API_KEY
ARG GOOGLE_GENERATIVE_AI_API_KEY
ARG OLLAMA_API_BASE_URL
ARG XAI_API_KEY
ARG TOGETHER_API_KEY
ARG TOGETHER_API_BASE_URL
ARG VITE_LOG_LEVEL=debug
ARG DEFAULT_NUM_CTX

ENV GROQ_API_KEY=${GROQ_API_KEY} \
    HuggingFace_API_KEY=${HuggingFace_API_KEY} \
    OPENAI_API_KEY=${OPENAI_API_KEY} \
    ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
    OPEN_ROUTER_API_KEY=${OPEN_ROUTER_API_KEY} \
    GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY} \
    OLLAMA_API_BASE_URL=${OLLAMA_API_BASE_URL} \
    XAI_API_KEY=${XAI_API_KEY} \
    TOGETHER_API_KEY=${TOGETHER_API_KEY} \
    TOGETHER_API_BASE_URL=${TOGETHER_API_BASE_URL} \
    AWS_BEDROCK_CONFIG=${AWS_BEDROCK_CONFIG} \
    VITE_LOG_LEVEL=${VITE_LOG_LEVEL} \
    DEFAULT_NUM_CTX=${DEFAULT_NUM_CTX}\
    RUNNING_IN_DOCKER=true

RUN mkdir -p ${WORKDIR}/run
CMD pnpm run dev --host
