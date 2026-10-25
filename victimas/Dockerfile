FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends nginx iproute2 iputils-ping && rm -rf /var/lib/apt/lists/*
CMD ["nginx", "-g", "daemon off;"]
