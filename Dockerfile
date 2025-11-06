FROM mcr.microsoft.com/playwright:v1.44.0

WORKDIR /workspace

COPY package*.json ./

RUN npm install --quiet
RUN npx playwright install --with-deps

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mutt \
    zip \
    ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .

RUN chmod +x run_tests.sh

CMD ["./run_tests.sh"]

