from pipelines.utils.pipeline import Pipeline, Step
from google.cloud import bigquery

import json
import ast
import datetime
from google.cloud import storage

_output_schema = [
    bigquery.SchemaField("customer", "STRING"),
    bigquery.SchemaField("id", "STRING"),
    bigquery.SchemaField("billing_period", "INT64"),
    bigquery.SchemaField("billing_period_unit", "STRING"),
    bigquery.SchemaField("customer_id", "STRING"),
    bigquery.SchemaField("status", "STRING"),
    bigquery.SchemaField("current_term_start", "TIMESTAMP"),
    bigquery.SchemaField("current_term_end", "TIMESTAMP"),
    bigquery.SchemaField("next_billing_at", "TIMESTAMP"),
    bigquery.SchemaField("created_at", "TIMESTAMP"),
    bigquery.SchemaField("started_at", "TIMESTAMP"),
    bigquery.SchemaField("activated_at", "TIMESTAMP"),
    bigquery.SchemaField("created_from_ip", "STRING"),
    bigquery.SchemaField("updated_at", "TIMESTAMP"),
    bigquery.SchemaField("has_scheduled_changes", "BOOLEAN"),
    bigquery.SchemaField("channel", "STRING"),
    bigquery.SchemaField("resource_version", "INT64"),
    bigquery.SchemaField("deleted", "BOOLEAN"),
    bigquery.SchemaField("object", "STRING"),
    bigquery.SchemaField("coupon", "STRING"),
    bigquery.SchemaField("currency_code", "STRING"),
    bigquery.SchemaField("subscription_items", "STRING"),
    bigquery.SchemaField("item_tiers", "STRING"),
    bigquery.SchemaField("coupons", "STRING"),
    bigquery.SchemaField("due_invoices_count", "INT64"),
    bigquery.SchemaField("due_since", "TIMESTAMP"),
    bigquery.SchemaField("total_dues", "INT64"),
    bigquery.SchemaField("mrr", "INT64"),
    bigquery.SchemaField("exchange_rate", "FLOAT64"),
    bigquery.SchemaField("base_currency_code", "STRING"),
    bigquery.SchemaField("has_scheduled_advance_invoices", "BOOLEAN"),
    bigquery.SchemaField("create_pending_invoices", "BOOLEAN"),
    bigquery.SchemaField("auto_close_invoices", "BOOLEAN"),
    bigquery.SchemaField("auto_collection", "STRING"),
    bigquery.SchemaField("offline_payment_method", "STRING"),
    bigquery.SchemaField("created_date", "DATE"),
]

class LoadJsonStep(Step):
    def __init__(self, data: any = {"project_id": None, "bucket_name": None, "blob_name": None}):
        super().__init__(data)

    def process(self):
        client = storage.Client()
        bucket = client.get_bucket(self.data.get('bucket_name'))
        blob = bucket.blob(self.data.get('blob_name'))
        json_file_path = '/tmp/etl.json'
        blob.download_to_filename(json_file_path)

        with open(json_file_path, 'r') as j:
            contents = ast.literal_eval(j.read())
                
        contents = [dict(customer=x.get('customer'), **x.get('subscription')) for x in contents['list']]
        return (contents, self.data.get('project_id'))
    
class ReformatJsontoString(Step):
    def process(self):
        contents, project_id = self.data
        cols_convert = ['customer', 'subscription_items', 'coupons', 'item_tiers']
        contents = [{k: json.dumps(v) if k in cols_convert else v for k, v in x.items()} for x in contents]
        return (contents, project_id)
    
class ProcessTimestamps(Step):
    def process(self):
        contents, project_id = self.data
        cols_convert = ['current_term_start', 'current_term_end', 'next_billing_at', 'created_at', 'started_at', 'activated_at', 'updated_at', 'due_since']
        contents = [{k: datetime.datetime.fromtimestamp(int(v)).strftime('%Y-%m-%d %H:%M:%S') if k in cols_convert else v for k, v in x.items()} 
                    for x in contents]
        contents = [
            dict(created_date=d.get('created_at')[:10], **d)
            for d in contents
        ]
        return (contents, project_id)
    
class LoadToBQ(Step):
    def process(self):
        dataset_id = "source"
        tmp_dataset_id = "tmp"
        table_name = "json_etl"

        contents, project_id = self.data
        client = bigquery.Client(project=project_id)
        _temp_table = client.dataset(tmp_dataset_id).table(table_name)
        output_table = client.dataset(dataset_id).table(table_name)

        # Create a temporary table to store the data
        create_temp_table = client.load_table_from_json(
            json_rows=contents, 
            destination=_temp_table, 
            job_config=bigquery.LoadJobConfig(
                schema=_output_schema,
                write_disposition="WRITE_TRUNCATE"
            )
        )
        create_temp_table.result()

        # Create table if not exists with _output_schema
        table = bigquery.Table(output_table, schema=_output_schema)
        table.time_partitioning = bigquery.TimePartitioning(field="created_date")
        table = client.create_table(table, exists_ok=True)

        # Load data into the table incrementally using the temporary table
        query = f"""
            BEGIN 
            DECLARE src_range STRUCT<date_min DATE, date_max DATE> --115 MB processed
            DEFAULT(SELECT STRUCT(
            MIN(created_date) AS date_min,  
            MAX(created_date) AS date_max) FROM {tmp_dataset_id}.{table_name});

            MERGE INTO {dataset_id}.{table_name} T
            USING (
            SELECT *
            FROM {tmp_dataset_id}.{table_name}
            WHERE created_date BETWEEN src_range.date_min AND src_range.date_max
            ) S 
            ON T.id = S.id
            WHEN MATCHED THEN UPDATE SET {', '.join([f"T.{field.name} = S.{field.name}" for field in _output_schema])}
            WHEN NOT MATCHED THEN INSERT ROW;
            END;
        """
        job = client.query(query)
        job.result()
        return 'SUCCESS';

def pipeline(initial_data): 
    return Pipeline(
        [LoadJsonStep, ReformatJsontoString, ProcessTimestamps, LoadToBQ], 
        initial_data
    )
