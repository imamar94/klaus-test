import subprocess
import os

# Define your project id and composer environment name
project_id = 'klaus-test-420018'
sa_email = 'etlpipeline@klaus-test-420018.iam.gserviceaccount.com'
composer_environment = 'etl-environment'
location = 'us-central1'  # update this to your composer location

# Get the absolute path of the current file
file_path = os.path.abspath(__file__)

# Get the directory containing the current file
file_directory = os.path.dirname(file_path)

# Construct the relative path to the credentials file
credentials_path = os.path.join("/".join(file_directory.split("/")[:-1]), 'terraform/credentials/composer_credentials.json')
dag_directory = os.path.join(file_directory, 'dags/')

# Set the GOOGLE_APPLICATION_CREDENTIALS environment variable
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path

# Get list of all DAG files
dag_files = [f for f in os.listdir(dag_directory) if f.endswith('.py')]


if __name__ == '__main__':
    cmd = (
        f'gcloud auth activate-service-account {sa_email}'
        f' --key-file {credentials_path}'
        f' --project {project_id}'
    )
    subprocess.run(cmd, shell=True, check=True)
    # Loop over all DAG files and upload them
    for dag_file in dag_files:
        print(f'Uploading DAG file: {dag_file}')
        dag_file_path = os.path.join(dag_directory, dag_file)
        
        # Construct the gcloud command
        cmd = ('gcloud composer environments storage dags import '
            f'--project {project_id} --environment {composer_environment} '
            f'--location {location} --source {dag_file_path}')
        print(cmd)
        
        # Execute the command
        subprocess.run(cmd, shell=True, check=True)
