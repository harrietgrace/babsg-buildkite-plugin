# CHANGELOG

## 0.0.3 (2018-01-11)

### ECR Manager

* Added a "release" mode that pushes a container matching the git tag that triggered the build, then runs a cleanup
* Added a "python2" build mode that downloads a pip cache before building the docker container

## v0.0.2 (2017-11-23)

* Amended coverage for RSpec and Python unittest CodeClimate Coverage tasks to include Buildkite ENV.
* Added YARD support

## v0.0.1 (2017-11-06)

* Initial release.
