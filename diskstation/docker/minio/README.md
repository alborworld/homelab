The file [policy.json](./policy.json) is a policy that allows Minio to access the S3 bucket `tfstate`.


```
mc admin accesskey create alborworld root \
  --policy /path/to/policy.json \
  --name "alborworld" \
```