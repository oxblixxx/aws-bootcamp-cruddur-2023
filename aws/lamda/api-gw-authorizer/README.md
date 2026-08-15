Zip the file 

```sh
 zip -r api-gw-authorizer.zip api-gw-authorizer/
```

```sh
aws lambda update-function-code --function-name api-gw-cognito-authorizer   --zip-file fileb://api-gw-authorizer.zip
```