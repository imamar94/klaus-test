variable "project-config" {
  type = map(string)
  default = {
    project = "klaus-test-420018"
    region  = "us-central1"
    credentials = "credentials/credentials.json"
    bucket = "klaus-test-bucket"
    default_location = "US"
  }
}

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

provider "google" {
  project     = var.project-config.project
  credentials = file(var.project-config.credentials)
  region  = var.project-config.region
}

## GCP Storage & upload initial data

resource "google_storage_bucket" "klaus-test-bucket" {
  name     = var.project-config.bucket
  location = var.project-config.default_location
  force_destroy = true
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
  location = var.project-config.default_location
}


## BQ DBT SA
resource "google_service_account" "bigquery_sa_dbt" {
  account_id   = "bq-sa-dbt"
  display_name = "BigQuery Service Account DBT"
}

resource "google_project_iam_member" "bq-data-editor-iam" {
  for_each = toset([ "roles/bigquery.user", "roles/bigquery.dataEditor", "roles/storage.objectViewer", "roles/bigquery.connectionUser" ])
  project = var.project-config.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.bigquery_sa_dbt.email}"
}

resource "google_bigquery_dataset_access" "bq-dataset-editor-access" {
  for_each = toset(["source", "model"])
  dataset_id = each.value
  role       = "roles/bigquery.dataEditor"
  user_by_email = google_service_account.bigquery_sa_dbt.email
}

resource "google_service_account_key" "bigquery_sa_dbt_key" {
  service_account_id = google_service_account.bigquery_sa_dbt.account_id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "service_account_dbt" {
  content           = base64decode(google_service_account_key.bigquery_sa_dbt_key.private_key)
  filename          = "credentials/bq_sa_dbt.json"
}

## BQ SA Data Reader

resource "google_service_account" "bq-sa-data-reader" {
  account_id   = "bq-sa-datareader"
  display_name = "BigQuery Service Account for Data Reader"
}

resource "google_project_iam_member" "bigquery-data-reader-iam" {
  for_each = toset([ "roles/bigquery.dataViewer", "roles/storage.objectViewer", "roles/bigquery.jobUser" ])
  project = var.project-config.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.bq-sa-data-reader.email}"
}

resource "google_service_account_key" "bigquery_sa_datareader_key" {
  service_account_id = google_service_account.bq-sa-data-reader.account_id
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "service_account_datareader" {
  content           = base64decode(google_service_account_key.bigquery_sa_datareader_key.private_key)
  filename          = "credentials/bq_sa_datareader.json"
}

## BQ Tables

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

  depends_on = [ google_storage_bucket_object.upload-inital-data, google_bigquery_dataset.source ]
}
