import datetime

from airflow import models
from airflow.operators import python_operator
from pipelines.pipeline_etl_json import pipeline

default_dag_args = {
    "start_date": datetime.datetime(2024, 4, 13),
    "schedule_interval": datetime.timedelta(days=1),
    "dag_title": "extract_json_etl"
}

initial_data = {
    "project_id": "klaus-test-420018",
    "bucket_name": "klaus-test-bucket",
    "blob_name": "data/etl.json"
}


with models.DAG(
    default_dag_args.get("dag_title"),
    default_args=default_dag_args,
) as dag:
    python_job = python_operator.PythonOperator(
        task_id="run-pipeline", python_callable=pipeline(initial_data).run
    )
