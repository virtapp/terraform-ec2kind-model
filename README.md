
![eksarchi](https://github.com/user-attachments/assets/85341846-7997-4a4b-9c67-5254563e36fc)


## Terraform Provisioner Model | Kubernetes  🚀🚀🚀



🎯  Key Features
```
✅ Deploy the Infrastructure
✅ Launch the EC2 instances
✅ Bootstrap the installation workflow
✅ Prepare Software Installation
✅ Configure Server
```

🚀 
```
terraform init
terraform validate
terraform plan -var-file="template.tfvars"
terraform apply -var-file="template.tfvars" -auto-approve
```

🧩 Config 

```
scp -i ~/.ssh/<your pem file> <your pem file> ec2-user@<terraform instance public ip>:/home/ec2-user
chmod 400 <your pem file>
```

