This directory creates a script to push to ecr

Your registry Id, IS YOUR VALUE FOR ACCOUNT WHEN YOU RUN `aws sts get-caller-identity"

aws ecr create-repository --repository-name frontend-react --generate-cli-skeleton > create-ecr.json




```sh
i Info → Not all multiplatform-content is present and only the available single-platform image was pushed
         sha256:7f404d09ceb780c51f4fac7592c46b8f21211474aacce25389eb0df06aaa7472 -> sha256:46a10b2d8f2e9ae5c5e8ffedd5ae18a960d64b8c39c09e24fe2ee41d7148c249
```

Currently, frontend repository is set to immutable, so the version number needs to be changed when images are pushed, the backend works as the same to latest which aligns with the task definition.
But for frontend, use this command to create and tag image

```sh
./build-image  frontend-react -t v5
```

Then proceed to task-definition to update the version number and update the task. 