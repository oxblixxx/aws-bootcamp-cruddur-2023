# Amazon ECR

This directory contains scripts for creating Amazon ECR repositories and pushing Docker images.

## Get Your AWS Account ID

Your ECR registry ID is your AWS Account ID. Retrieve it with:

```bash
aws sts get-caller-identity
```
---

## Create an ECR Repository

Generate the repository creation template:

```bash
aws ecr create-repository \
  --repository-name frontend-react \
  --generate-cli-skeleton > create-ecr.json
```

Review and modify the generated JSON if necessary before creating the repository.

---

## Pushing Images

While pushing an image, you may see a message similar to:

```text
Info → Not all multiplatform-content is present and only the available single-platform image was pushed
```

This is an informational message indicating that only the available platform image was pushed.

---

## Image Tagging

The **frontend-react** repository is configured with **immutable tags**. As a result, every new image must be pushed with a unique version tag.

Example:

```bash
./build-image frontend-react -t v5
```

After pushing a new image, update the image tag in the [ECS task definition](aws/ecs/task-definitions/frontend-react.json) and deploy the new task revision.

The backend repository follows the same workflow, except it currently uses **MUTABLE** tag with the `latest` tag, which matches the existing ECS task definition.