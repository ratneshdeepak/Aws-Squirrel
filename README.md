# Aws Class
The class allows you to consume AWS services

## Create a Aws Account access credentials

In order to use the AWS SDK, you’ll first need to [create a Aws Account access credentials](https://aws.amazon.com/).

## Constructor(access_key, secret_key, region)

The Aws constructor takes 3 parameters that constitute your AWS app's Auth credentials. You can find these in the *Security Credentials* section of your AWS account.

```squirrel
aws <- Aws(access_key, secret_key, region)
```

To publish a message to sns topic

```squirrel
aws.snsPublish("TopicArn", "Subject", "String message");
```
