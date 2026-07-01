This directory creates a script to push to ecr

Your registry Id, IS YOUR VALUE FOR ACCOUNT WHEN YOU RUN `aws sts get-caller-identity"

aws ecr create-repository --repository-name frontend-react --generate-cli-skeleton > create-ecr.json




```sh
i Info → Not all multiplatform-content is present and only the available single-platform image was pushed
         sha256:7f404d09ceb780c51f4fac7592c46b8f21211474aacce25389eb0df06aaa7472 -> sha256:46a10b2d8f2e9ae5c5e8ffedd5ae18a960d64b8c39c09e24fe2ee41d7148c249
```