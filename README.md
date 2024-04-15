# Klaus Test Project

This project contains the codebase for the Klaus Test ETL pipeline and data model.

## Prerequisites

Before you begin, ensure you have met the following requirements:

1. Install the required packages listed in the `requirements.txt` file. You can do this by running `pip install -r requirements.txt` in your terminal.

2. Copy the provided credentials into the `terraform/credentials/` directory. These credentials are necessary for accessing certain resources. Two important credential in order to run this project smoothly:
   - `bq_sa_dbt.json`
   - `composer_credentials.json`

## Running the Data Model

To run the data model, follow these steps:

1. Change your working directory to `datamodel/klaus_dbt` using the command `cd datamodel/klaus_dbt`.

2. Create / edit profile config in `~/.dbt/profiles.yml` as follow, replace `<your-path-to-repo>` with the actual path to your repository:
   
```yaml
klaus_dbt:
  outputs:
    dev:
      job_execution_timeout_seconds: 600
      job_retries: 1
      keyfile: <your-path-to-repo>/klaus-test/terraform/credentials/bq_sa_dbt.json
      location: US
      method: service-account
      priority: interactive
      project: klaus-test-420018
      schema: dev
      threads: 4
      type: bigquery
    prod:
      job_execution_timeout_seconds: 600
      job_retries: 1
      keyfile: <your-path-to-repo>/klaus-test/terraform/credentials/bq_sa_dbt.json
      location: US
      method: service-account
      priority: interactive
      project: klaus-test-420018
      schema: prod
      threads: 4
      type: bigquery
  target: dev
```

3. Clean any existing dbt artifacts and install dependencies by running `dbt clean && dbt deps`.

4. Run the transformation with the following commands:

```bash
# Run ETL to production
dbt run --target prod

# Run tests
dbt test --target prod
```

## Running the ETL Pipeline with Google Cloud Composer

Follow these steps to run the ETL pipeline:

1. Open your terminal and navigate to the `composer/` directory in the project root. You can do this by running the command `cd composer/`.

2. Inside the `composer/` directory, you will find a `dags/` directory. This is where all your Directed Acyclic Graphs (DAGs) for Airflow are stored. If you want to submit a new DAG, place your Python script in this directory.

3. If you are using the Pipeline/Step mini framework, you can build your pipeline inside the `composer/dags/pipelines/` directory. Each pipeline should be a separate Python script and should follow the structure and syntax of the existing pipeline scripts.

4. Once your DAGs are in place, you can deploy them to your Airflow environment. To do this, run the command `python main.py` inside the `composer/` directory. This script will upload your DAGs to the Airflow environment.

Please ensure that you have the necessary permissions and that your Google Cloud SDK is properly configured before running these commands.
