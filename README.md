![454622268-85341846-7997-4a4b-9c67-5254563e36fc](https://github.com/user-attachments/assets/cf54a003-2bc4-4c61-92aa-6a74a28682c5)

## Terraform Provisioner | Model  🚀🚀🚀



🎯  Key Features
```
✅ Deploy the Infrastructure
✅ Launch the EC2 Instance
✅ Install Dependencies
✅ Prepare Software Installation
✅ Post-Configuration
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

