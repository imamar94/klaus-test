from pipelines.utils.pipeline import Pipeline, Step
from google.cloud import bigquery

import json
import ast
from google.cloud import storage


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
        cols_convert = ['customer', 'subscription_items', 'coupons']
        contents = [{k: json.dumps(v) if k in cols_convert else v for k, v in x.items()} for x in contents]
        return (contents, project_id)
    
class LoadToBQ(Step):
    def process(self):
        dataset_id = "source"
        table_name = "json_etl"

        contents, project_id = self.data
        client = bigquery.Client(project=project_id)
        table_ref = client.dataset(dataset_id).table(table_name)

        job_config = bigquery.LoadJobConfig(
            schema=[
                bigquery.SchemaField("customer", "STRING"),
                bigquery.SchemaField("id", "STRING"),
                bigquery.SchemaField("billing_period", "INT64"),
                bigquery.SchemaField("billing_period_unit", "STRING"),
                bigquery.SchemaField("customer_id", "STRING"),
                bigquery.SchemaField("status", "STRING"),
                bigquery.SchemaField("current_term_start", "INT64"),
                bigquery.SchemaField("current_term_end", "INT64"),
                bigquery.SchemaField("next_billing_at", "INT64"),
                bigquery.SchemaField("created_at", "INT64"),
                bigquery.SchemaField("started_at", "INT64"),
                bigquery.SchemaField("activated_at", "INT64"),
                bigquery.SchemaField("created_from_ip", "STRING"),
                bigquery.SchemaField("updated_at", "INT64"),
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
                bigquery.SchemaField("due_since", "INT64"),
                bigquery.SchemaField("total_dues", "INT64"),
                bigquery.SchemaField("mrr", "INT64"),
                bigquery.SchemaField("exchange_rate", "FLOAT64"),
                bigquery.SchemaField("base_currency_code", "STRING"),
                bigquery.SchemaField("has_scheduled_advance_invoices", "BOOLEAN"),
                bigquery.SchemaField("create_pending_invoices", "BOOLEAN"),
                bigquery.SchemaField("auto_close_invoices", "BOOLEAN")
            ],
            write_disposition="WRITE_TRUNCATE"
        )

        job = client.load_table_from_json(
            json_rows=contents, 
            destination=table_ref, 
            job_config=job_config
        )

        job.result()
        return job.result()

def pipeline(initial_data): 
    return Pipeline(
        [LoadJsonStep, ReformatJsontoString, LoadToBQ], 
        initial_data
    )
