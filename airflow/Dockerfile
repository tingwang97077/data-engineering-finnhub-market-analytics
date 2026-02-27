FROM apache/airflow:2.10.5-python3.11

USER root
COPY airflow/requirements.txt /tmp/requirements.txt
USER airflow

ARG AIRFLOW_VERSION=2.10.5
ARG PYTHON_VERSION=3.11
ARG CONSTRAINTS_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

RUN pip install --no-cache-dir --constraint "${CONSTRAINTS_URL}" -r /tmp/requirements.txt
