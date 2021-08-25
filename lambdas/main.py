import boto3
import json
import os
import requests
from datetime import datetime


def get_file_from_s3(key: str):
    client = boto3.client("s3")

    response = client.get_object(
        Bucket="js-input-bucket-tech-talk-tf", Key=key
    )

    return response


def parse_file(file) -> []:
    contents = file["Body"].read()

    locations = list(json.loads(contents)["locations"])

    return locations


def generate_api_url(location: str):
    key = os.getenv("WEATHER_API_KEY")

    url = f"https://api.weatherapi.com/v1/current.json"

    return f"{url}?key={key}&q={location}"


def call_api(location):
    response = requests.get(generate_api_url(location))

    if response.status_code != 200:
        raise Exception

    return response.json()


def save_data(data: []):
    locations = []

    for location in data:
        l = location["location"]

        locations.append({
            "PutRequest": {
                "Item": {
                    "location": {
                        "S": f"{l['name']}, {l['region']}, {l['country']}"
                    },
                    "localtime": {
                        "S": str(l["localtime"])
                    },
                    "celsius": {
                        "S": str(location["current"]["temp_c"])
                    },
                    "fahrenheit": {
                        "S": str(location["current"]["temp_f"])
                    },
                    "last_updated": {
                        "S": str(datetime.now())
                    },
                }
            }
        })

    client = boto3.client("dynamodb")

    client.batch_write_item(
        RequestItems={
            "js-weather-tf": locations
        }
    )


def lambda_handler(event, context):
    key = event["Records"][0]["s3"]["object"]["key"]

    file = get_file_from_s3(key)

    locations = parse_file(file)

    data = []
    for location in locations:
        response = call_api(location)
        data.append(response)

    save_data(data)
