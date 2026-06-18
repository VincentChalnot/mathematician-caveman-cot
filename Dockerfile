FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/VincentChalnot/LiteBench.git /opt/litebench && \
    pip install /opt/litebench

COPY requirements.txt .
RUN pip install -r requirements.txt

ENTRYPOINT ["python", "run.py"]
