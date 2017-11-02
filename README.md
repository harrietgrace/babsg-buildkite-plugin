# Cassandra Buildkite Plugin

![Cassandra](cassandra.jpg)

## Usage
```
steps:
  - plugins:
    github.com/cozero/cassandra-buildkite-plugin#v0.0.1:
      install_path: /var/cass/bin
      ecr_cleanup: true
```

## Licence

MIT (see [LICENCE](LICENCE))
