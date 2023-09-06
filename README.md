Prerequisites:
1. Buy a domain.
2. Buy a SSl certificate to it and get its arn.
3. Replace the bucket names(both origin and log buckets) as unique bucket name.
3. keep the index.html and error.html file in the directory where your main.tf file is placed.
4. create access key and secret key and replace it with the providers.(Note: Dont expose your access credentials in github or any public platform)
5. Install terraform
6. Give your SSL certificate arn in the Distribution module.

Steps
1. Verify your current directory has main.tf(terraform file), index.html(origin host file) and error.html(error file).
2. Type command terraform init and terraform apply
3. set the cloud front arn in the CNAME record of your domain.
4. Check with domain name whether your domain is rendering with the index.html file. 
