
Install

```sh
sudo apt update
sudo apt install ruby ruby-dev ruby-bundler
```

cd pwd

```sh
bundle config set --local path vendor/bundle
```


zip -r cruddur-S3-presigned-url.zip function.rb vendor/

aws lambda update-function-code --function-name CruddurS3PresignedUrl   --zip-file fileb://function.zip



aws lambda publish-layer-version \
  --layer-name cruddur-S3-presigned-url-dependencies \
  --zip-file fileb://cruddur-S3-presigned-url.zip \
  --compatible-runtimes ruby4.0

  arn:aws:lambda:us-east-1:193654356005:layer:cruddur-S3-presigned-url-dependencies


  aws lambda update-function-configuration \
  --function-name CruddurS3PresignedUrl \
  --layers arn:aws:lambda: arn:aws:lambda:us-east-1:193654356005:layer:cruddur-S3-presigned-url-dependencies


  aws lambda update-function-configuration \
  --function-name CruddurS3PresignedUrl \
  --layers arn:aws:lambda:us-east-1:193654356005:layer:cruddur-S3-presigned-url-dependencies:1




  scp -i prod-sutneppaa-195 -R sutneppa@147.93.28.195:/home/sutneppa/aws-bootcamp-cruddur-2023/aws/lamda/cruddur-S3-presigned-url/cruddur-S3-presigned-url.zip .



   docker run -v "$PWD":/var/task -w /var/task public.ecr.aws/sam/build-ruby4.0:latest bash -c "
  bundle config set --local path 'vendor/bundle' &&
  bundle install &&
  zip -r function.zip function.rb vendor Gemfile Gemfile.lock