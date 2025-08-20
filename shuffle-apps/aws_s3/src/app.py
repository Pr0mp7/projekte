import socket
import asyncio
import time
import random
import json
import os
import boto3
import botocore
from botocore.config import Config

from shuffle_sdk import AppBase

class AWSS3(AppBase):
    __version__ = "1.0.0"
    app_name = "AWS S3"  

    def __init__(self, redis, logger, console_logger=None):
        """
        Each app should have this __init__ to set up Redis and logging.
        :param redis:
        :param logger:
        :param console_logger:
        """
        super().__init__(redis, logger, console_logger)

    def auth_s3(self, access_key, secret_key, region, endpoint_url=None):
        """
        Authenticate to S3 or MinIO
        :param endpoint_url: Optional custom endpoint for MinIO
        """
        my_config = Config(
            region_name = region,
            signature_version = "s3v4",
            retries = {
                'max_attempts': 10,
                'mode': 'standard'
            },
        )
        
        # Build kwargs based on whether we have a custom endpoint
        kwargs = {
            'config': my_config,
            'aws_access_key_id': access_key,
            'aws_secret_access_key': secret_key,
        }
        
        # Add endpoint configuration for MinIO or custom S3
        if endpoint_url and endpoint_url.strip():
            kwargs['endpoint_url'] = endpoint_url.strip()
            # Determine if we should use SSL based on URL
            kwargs['use_ssl'] = endpoint_url.startswith('https')
            # For self-signed certificates in airgapped environments
            kwargs['verify'] = False
            
        self.s3 = boto3.resource('s3', **kwargs)
        return self.s3

    def list_buckets(self, access_key, secret_key, region, endpoint_url=None):
        """List all S3 buckets"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            newlist = client.list_buckets()
            return json.dumps(newlist, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def create_bucket(self, access_key, secret_key, region, bucket_name, access_type, endpoint_url=None):
        """Create a new S3 bucket"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            
            # For MinIO or us-east-1, don't specify LocationConstraint
            if region == 'us-east-1' or endpoint_url:
                creation = client.create_bucket(
                    Bucket=bucket_name,
                    ACL=access_type,
                )
            else:
                creation = client.create_bucket(
                    Bucket=bucket_name,
                    ACL=access_type,
                    CreateBucketConfiguration={
                        'LocationConstraint': region
                    },
                )
            
            return json.dumps({"success": True, "result": creation}, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def block_ip_access(self, access_key, secret_key, region, bucket_name, ip, endpoint_url=None):
        """Block IP access to bucket (AWS only, may not work with MinIO)"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client

            ip_policy = {
                'Effect': 'Deny',
                "Principal": "*",
                "Action": "s3:*",
                "Resource": [
                    f"arn:aws:s3:::{bucket_name}/*",
                    f"arn:aws:s3:::{bucket_name}"
                ],
                "Condition": {
                    "IpAddress": {
                        "aws:SourceIp": [ip]
                    }
                }
            }

            json_policy = {}
            try:
                result = client.get_bucket_policy(Bucket=bucket_name)
                policy = result.get("Policy", "{}")
                if ip in policy:
                    return json.dumps({"success": False, "error": f"IP {ip} is already in this policy"})
                
                json_policy = json.loads(policy)
                json_policy.setdefault("Statement", []).append(ip_policy)
            except botocore.exceptions.ClientError:
                # Create new policy if none exists
                json_policy = {
                    'Version': '2012-10-17',
                    'Statement': [ip_policy]
                }

            bucket_policy = json.dumps(json_policy)
            putaction = client.put_bucket_policy(Bucket=bucket_name, Policy=bucket_policy)
            
            return json.dumps({"success": True, "message": f"Successfully blocked IP {ip}"})
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def bucket_request_payment(self, access_key, secret_key, region, bucket_name, endpoint_url=None):
        """Get bucket request payment configuration"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            result = client.get_bucket_request_payment(Bucket=bucket_name)
            return json.dumps(result, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def bucket_replication(self, access_key, secret_key, region, bucket_name, endpoint_url=None):
        """Get bucket replication configuration"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            result = client.get_bucket_replication(Bucket=bucket_name)
            return json.dumps(result, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def bucket_policy_status(self, access_key, secret_key, region, bucket_name, endpoint_url=None):
        """Get bucket policy status"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            result = client.get_bucket_policy_status(Bucket=bucket_name)
            return json.dumps(result, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def bucket_logging(self, access_key, secret_key, region, bucket_name, endpoint_url=None):
        """Get bucket logging configuration"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            result = client.get_bucket_logging(Bucket=bucket_name)
            return json.dumps(result, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def upload_file_to_bucket(self, access_key, secret_key, region, bucket_name, bucket_path, file_id, endpoint_url=None):
        """Upload a file to S3 bucket"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            
            found_file = self.get_file(file_id)
            if not found_file:
                return json.dumps({"success": False, "error": "File not found in Shuffle"})
            
            s3_response = client.put_object(
                Bucket=bucket_name, 
                Key=bucket_path, 
                Body=found_file.get("data", "")
            )
            
            return json.dumps({"success": True, "result": s3_response}, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def delete_file_from_bucket(self, access_key, secret_key, region, bucket_name, bucket_path, endpoint_url=None):
        """Delete a file from S3 bucket"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            
            s3_response = client.delete_object(Bucket=bucket_name, Key=bucket_path)
            return json.dumps({"success": True, "result": s3_response}, default=str)
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

    def download_file_from_bucket(self, access_key, secret_key, region, bucket_name, filename, endpoint_url=None):
        """Download a file from S3 bucket"""
        try:
            self.s3 = self.auth_s3(access_key, secret_key, region, endpoint_url)
            client = self.s3.meta.client
            
            s3_response_object = client.get_object(Bucket=bucket_name, Key=filename)
            object_content = s3_response_object['Body'].read()
            
            filedata = {
                "data": object_content,
                "filename": filename,
            }
            ret = self.set_files([filedata])
            
            if isinstance(ret, list) and len(ret) == 1:
                return json.dumps({
                    "success": True,
                    "file_id": ret[0],
                    "filename": filename,
                    "length": len(object_content),
                })
            
            return json.dumps({
                "success": False,
                "error": f"Failed to store file: {ret}"
            })
        except botocore.exceptions.ClientError as e:
            return json.dumps({"success": False, "error": str(e)})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

if __name__ == "__main__":
    AWSS3.run()