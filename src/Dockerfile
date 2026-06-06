# Stage 1: Build Stage
ARG PYTHON_VERSION=3.8
FROM python:${PYTHON_VERSION}-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Run Stage
FROM python:${PYTHON_VERSION}-slim AS run

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser

COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

CMD ["python", "manage.py", "runserver", "0.0.0.0:8080"]