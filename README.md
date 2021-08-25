## Prereqs
- Install Python (3.8 preferably) [here](https://www.python.org/downloads/)
- Install Terraform [here](https://www.terraform.io/downloads.html)
- Install AWS CLI (v2) [here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- Have an AWS area set up
- Can connect to AWS locally (Run `aws s3 ls`, if nothing fails you should be good to go)
- Get an API key (free) from https://www.weatherapi.com/


## Clone project
`git clone https://github.com/josh-scargill/aws_tech_talk.git`

`cd aws_tech_talk`


## Create venv & activate
`python -m venv venv`

Activate with either:
- Windows cmd.exe - `venv\Scritps\activate.bat`
- Windows Powershell - `venv/Scripts/Activate.ps1`
- Mac/Linux - `source venv/bin/activate` 


## Install required packages in venv
`pip install boto3`

`pip install requests`

You can leave your venv by running `deactivate`. Please note that you need your venv to be activated to run the main.py script


## Set up your api key
You need to put it in 2 places, firstly as an environment variable `WEATHER_API_KEY`

Also line 53 in the terraform script


## Change resource names
At a minimum, S3 buckets are region unique, aka if you try to create one of these buckets in eu-west-2, it will probably fail because it already exists.

So change the bucket names to something unique to you
- `main.py` on Line 12
- `main.tf` on Line 19

Outside of that, you can also rename the lambda and dynamodb if you'd like, might be easier to find them by searching `js-`


## Terraform usage
`terraform init`

`terraform apply` # type `yes` when required
