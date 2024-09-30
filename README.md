# gitsync

**gitsync** is a lightweight bash-based tool designed to automatically check for remote changes in a specified Git repository and pull updates if necessary. The tool is containerized using Docker, allowing easy deployment in various environments. It can be used as a module in Docker Compose setups for seamless synchronization of repositories.

## Table of Contents

- [Features](#features)
- [Installation](#installation-and-usage)
- [Environment Variables](#environment-variables)
- [Usage with Docker Compose](#usage-with-docker-compose)
- [License](#license)

## Features

- Monitors a Git repository for remote changes and automatically pulls updates.
- Supports both SSH and HTTP/HTTPS Git remotes.
- Can handle private repositories with SSH keys or basic authentication.
- Easy integration into Docker Compose environments.

## Installation and usage

To build and run **gitsync** locally using Docker:

1. Clone this repository:

```bash
git clone https://github.com/TheArqsz/gitsync.git
cd gitsync
```

2. Build the Docker image:

```bash
docker build -t gitsync .
```

3. Run the container:

```bash
docker run -e BASIC_AUTH=1 -e USERNAME=YourUsername -e PASSWORD_OR_KEY_FILE=/run/secrets/password_or_key_secret -v /path/to/your/repo:/workspace -v git_password:/run/secrets/password_or_key_secret gitsync
```

or

```bash
docker run  -e SSH_PRIVATE_KEY_FILE=/id_rsa -v /path/to/your/repo:/workspace -v ~/.ssh/id_rsa:/id_rsa -e TIMEOUT=10 gitsync
```

etc.

The Docker image runs a bash script (`entrypoint.sh`) that will:

- Check if the provided directory is a valid Git repository.
- Fetch and pull changes from the remote repository, supporting both SSH and HTTPS remotes.
- Continuously check for updates at regular intervals defined by environment variables.

## Environment Variables

| Variable              | Description                                                                 | Required | Default Value | Example Values                    |
|-----------------------|-----------------------------------------------------------------------------|----------|---------------|----------------------------------|
| `BASIC_AUTH`          | Enables basic authentication for HTTP/HTTPS Git remotes. Set to `1` to use. | Yes (if http authentication required)     | None          | `1`                              |
| `USERNAME`            | The Git username for basic authentication.                                  | Yes (if http authentication required)      | None          | `GithubUser`                     |
| `PASSWORD_OR_KEY_FILE`| Path to the file containing the password or API key for basic authentication.| No (needs to be passed through [secrets](https://docs.docker.com/reference/compose-file/secrets/w))      | None          | `/run/secrets/password_or_key_secret` |
| `MAIN_BRANCH`         | The main branch to track and pull from.                                      | No       | `main`        | `main`, `master`                 |
| `TIMEOUT`             | The interval in seconds between sync checks.                                | No       | `60`          | `120`, `300`                     |
| `SSH_PRIVATE_KEY_FILE`| Path to the SSH private key for SSH Git remotes.                             | No       | `/id_rsa`     | `/root/.ssh/id_rsa`              |
| `VERBOSE`             | Enables verbose logging if set (useful for debugging).                      | No       | None          | `1` (any value)                  |

## Usage with Docker Compose

`gitsync` can be easily integrated as a module in a docker-compose.yml setup. Below is an example configuration:

```yaml
services:
  gitsync:
    image: thearqsz/gitsync:latest
    container_name: gitsync
    volumes:
      - $HOME/example-repo:/workspace
    environment:
      - BASIC_AUTH=1
      - USERNAME=GithubUser
      - PASSWORD_OR_KEY_FILE=/run/secrets/password_or_key_secret
    secrets:
      - password_or_key_secret

secrets:
  password_or_key_secret:
    environment: PASSWORD_OR_KEY
```

In this example:

- The local repository at `$HOME/example-repo` is mounted to the container's `/workspace` directory.
- The necessary credentials for Git authentication (username and password/API key) are passed via Docker secrets for enhanced security.

Other examples:

- [docker-compose.yml.example1](docker-compose.yml.example1)
- [docker-compose.yml.example2](docker-compose.yml.example2)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.
