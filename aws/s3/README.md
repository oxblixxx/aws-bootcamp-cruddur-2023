# Uploading a File to Amazon S3

This script uploads a local file to an Amazon S3 bucket and allows you to specify the destination filename.

## Usage

Make the file executable

```sh
chmod +x copy-image
```

```bash
./copy-image <destination-filename>
```

## Example

```bash
./copy-image fly.jpg
```

This uploads:

```text
./assets/bird.jpg
```

to:

```text
s3://assets.mustaphaops.online/avatars/original/fly.jpg
```

## Notes

* The source file is `./assets/bird.jpg`.
* `<destination-filename>` determines the name of the file stored in S3.
* You can choose any valid filename, for example:
  * `avatar.jpg`
  * `profile.png`
  * `user-123.jpeg`
* The `avatars/original/` path acts as the destination folder (prefix) within the S3 bucket.
* Also, this is used to test the lamda image processing function!
* Processed images are shown in `avatars/processed/`
