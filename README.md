# BabsG Buildkite Plugin

![BabsG](barbara.jpg)

> Photo [Genia Baida](https://flic.kr/p/nybGzq) [CC BY-NC-ND 2.0](https://creativecommons.org/licenses/by-nc-nd/2.0/)

## Usage
```
steps:
  - plugins:
    github.com/cozero/babsg-buildkite-plugin#v0.0.1:
      ecr_cleanup: true
```

## Configuration

### Docker

Generally speaking, your pipeline is going to be building and pulling some docker containers. So docker support is on by default. You'll need to do more than zero of the following:-

#### use_docker: false

This will disable docker helpers. No further action required.

#### Docker FQDN

Either set directly
```
docker_fqdn: 123123123123.dkr.ecr.ap-northeast-1.amazonaws.com
ecr_aws_region: ap-northeast-1 # this one is optional and defaults to ap-southeast-2
```

OR provide your account ID and ecr aws region and BabsG will build the FQDN for you
```
aws_account: 123123123123
ecr_aws_region: ap-northeast-1 # this one is optional and defaults to ap-southeast-2
```

#### Docker Repo Slug
```
docker_repo_slug: my-great-repository
```  

### Options

#### ecr_cleanup: true

Run the ecr_tag_cleanup step if a buildkite step exists with a non-zero code

#### elastic_beanstalk_env_name: my-special-environment

By default, we use the first 40 chars of $PLATFORM-$APPLICATION-$RUNTIME_ENV

#### install_path: path/to/install

By default, BabsG will install to .babsg. You can specify something else if for some reason this conflicts with your repo.

#### runtime_env: mega-prod

By default, we'll use $BUILDKITE_BRANCH and sub in production in place of master

#### s3v4_sigs: false

By default, we configure v4 signatures to support KMS. You can turn this off if you like.

## Licence

MIT (see [LICENCE](LICENCE))
