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

1. Clean any existing dbt artifacts and install dependencies by running `dbt clean && dbt deps`.

2. Run the transformation with the following commands:

```bash
# Run ETL to production
dbt run --target prod

# Run tests
dbt test --target prod
```
