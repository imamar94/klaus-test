provider "google" {
  project     = "klaus-test-420018"
  credentials = file("credentials/credentials.json")
  region  = "europe-west1"
}

## GCP Storage & upload initial data

variable "files" {
  # put the path to the files you want to upload here
  type = map(string)
  default = {
    "data/autoqa_ratings.csv" = "data/autoqa_ratings.csv"
    "data/autoqa_reviews.csv" = "data/autoqa_reviews.csv"
    "data/autoqa_root_cause.csv" = "data/autoqa_root_cause.csv"
    "data/conversations.csv" = "data/conversations.csv"
    "data/manual_rating.csv" = "data/manual_rating.csv"
    "data/manual_reviews.csv" = "data/manual_reviews.csv"
    "data/etl.json" = "data/etl.json"
  }
}

resource "google_storage_bucket" "klaus-test-bucket" {
  name     = "klaus-test-bucket"
  location = "EU"
}

resource "google_storage_bucket_object" "upload-inital-data" {
  for_each = var.files
  name     = each.value
  source   = "${path.module}/${each.key}"
  bucket   = google_storage_bucket.klaus-test-bucket.name
  depends_on = [ google_storage_bucket.klaus-test-bucket ]
}


## GCP BigQuery

resource "google_bigquery_dataset" "source" {
  dataset_id = "source"
  location = "EU"
}

resource "google_bigquery_dataset" "model" {
  dataset_id = "model"
  location = "EU"
}

resource "google_service_account" "bigquery_sa_dbt" {
  account_id   = "bq-sa-dbt"
  display_name = "BigQuery Service Account DBT"
}

resource "google_project_iam_member" "bigquery_job_user" {
  project = "klaus-test-420018"
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.bigquery_sa_dbt.email}"
}

resource "google_bigquery_dataset_access" "bigquery_access_source" {
  dataset_id = google_bigquery_dataset.source.dataset_id
  role    = "roles/bigquery.dataEditor"
  user_by_email   = google_service_account.bigquery_sa_dbt.email
}

resource "google_bigquery_dataset_access" "bigquery_access_model" {
  dataset_id = google_bigquery_dataset.model.dataset_id
  role    = "roles/bigquery.dataEditor"
  user_by_email   = google_service_account.bigquery_sa_dbt.email
}

resource "google_service_account_key" "bigquery_sa_dbt_key" {
  service_account_id = google_service_account.bigquery_sa_dbt.account_id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "service_account" {
  content           = base64decode(google_service_account_key.bigquery_sa_dbt_key.private_key)
  filename          = "credentials/bq_service_account.json"
}

resource "google_bigquery_table" "source-table" {
  for_each = { for f in var.files : f => f if strcontains(lower(f), ".csv") }

  dataset_id = google_bigquery_dataset.source.dataset_id
  table_id   = replace(replace(each.value, "data/", ""), ".csv", "")
  deletion_protection = false

  external_data_configuration {
    source_format = "CSV"
    source_uris = [
      "gs://${google_storage_bucket.klaus-test-bucket.name}/${each.value}",
    ]

    autodetect = true

    csv_options {
      allow_quoted_newlines = true
      skip_leading_rows = 1
      quote = "\""
    }
  }

  depends_on = [ google_storage_bucket_object.upload-inital-data ]
}