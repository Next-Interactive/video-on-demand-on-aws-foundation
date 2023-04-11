import paramiko
import boto3
import datetime
import os
import io
import zipfile

ROOT_PATH = os.environ.get('ROOT_PATH',"/arrivee")
BUCKET    = os.environ.get('BUCKET')
KANTAR_LOGS_PREFIX = os.environ.get('KANTAR_LOGS_PREFIX')
SFTP_SERVER   = os.environ.get('SFTP_SERVER')
SFTP_USERNAME    = os.environ.get('SFTP_USERNAME')
SSM_SFTP_PASSWORD    = os.environ.get('SSM_SFTP_PASSWORD',"mediametrie_sftp_password")
SFTP_PORT    = os.environ.get('SFTP_PORT',"22")
REGION       = os.environ.get('REGION',"eu-west-1")
ssm = boto3.client("ssm",region_name=REGION)

response = ssm.get_parameter(Name=SSM_SFTP_PASSWORD,WithDecryption=True)
password = response['Parameter']['Value']


transport = paramiko.Transport((SFTP_SERVER, int(SFTP_PORT)))
transport.connect(username=SFTP_USERNAME,password=password)
sftp_client = paramiko.SFTPClient.from_transport(transport)

s3 = boto3.client("s3")

today = datetime.date.today()

year = str(today.year)
month = f"{today.month:02d}"
day = f"{today.day:02d}"

def construct_zip_file():
   
    convention_prefix = f'formatted-logs/MMD_{year}{month}{day}_pubrmcbfmplay_L_V01.zip'
    # list all the objects (i.e., files) in the specified folder
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=f'{KANTAR_LOGS_PREFIX}/{year}/{month}/{day}')

    # extract the keys (i.e., paths) of the objects in the folder
    keys = [obj['Key'] for obj in response['Contents']]

    # create a ZipFile object in memory
    memory_file = io.BytesIO()
    with zipfile.ZipFile(memory_file, 'w') as zip_file:
        # iterate over the object keys and add each file to the zip archive
        for key in keys:
            # download the file contents from S3
            response = s3.get_object(Bucket=BUCKET, Key=key)
            file_contents = response['Body'].read()
            # add the file to the zip archive
            zip_file.writestr(key.split('/')[-1], file_contents)

    # upload the zip file to S3
    memory_file.seek(0)
    s3.upload_fileobj(memory_file, BUCKET, convention_prefix)

    return convention_prefix
    

def sftp_send(key):
    file= key.split('/')[-1]
    with sftp_client.open(f'{ROOT_PATH}/{file}', 'w') as f:
        s3.download_fileobj(BUCKET,key,f)


def lambda_handler(event, context):
    """
    Description:
        This function is in charge of sending daily Kantar LOGS to Mediametrie
    Args:
        event: default lambda arg
        context: default lambda arg
    Return:
        String
    """
    key = construct_zip_file()
    sftp_send(key)

    return "success"
