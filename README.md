# AnotherMedPot (AMP) - Prototype

This project offers a wrapper around the [honeypots](https://github.com/qeeqbox/honeypots/) project, specifically a fork with some additions regarding the DICOM and HL7 protocols, so it can run in a [Docker Compose](https://docs.docker.com/compose/) environment.
The unique feature of this project is that it allows you to run the honeypot on a raspberry pi, which aims at easily plugging it into a hospital network.

The project is not be confused with [medpot](https://github.com/schmalle/medpot), which also offers DICOM / HL7 in a honeypot context.

## TL;DR

```sh
./setup.sh
# then restart or run `newgrp docker`
docker compose up
```

## Initial Deployment

Will install Docker and the honeypot service.
Only works with Raspbian (now "Raspberry Pi OS").
Was tested with Raspbian "bullseye" 64-bit
(the 64-bit images are important because the Docker images are built for `arm64`).

```sh
./setup.sh
```

After installing Docker with the `setup.sh` script,
the user needs to reboot or log out and in again so that the group changes take effect
(alternatively `newgrp docker` may also work).

:warning: The `setup.sh` script is only intended for deployment
and not for local development (it expects `arm64` architecture).

## Running the honeypot

### Starting

The honeypot service can be started with Docker
(must be executed from the root folder of this repository):

```sh
docker compose up --detach
```

The container is configured to start automatically with the system.

### Stopping

Stopping is equally easy (must also be executed from the root folder of this repository):

```sh
docker compose down
```

## Updating

To download the newest Docker image(s) run

```shell
docker compose pull
```

After this, you need to stop and start the service (see above) for the update to take effect.

## Fetching logs

A webserver to fetch log files will run on port `55555`.
Access is limited to users configured in [.htpasswd](./.htpasswd).
The default honeypots config `config.json` contains logging to file and terminal in
JSON format.
The maximum log file size can be adjusted using the `max_bytes` option for each server
(`0` means unlimited).

### Syslog Logging

In addition to events that are logged to the shared folder, syslog logging can also be enabled.
With this, you can log events directly to a remote system.
You need to edit the following configuration parameters in the `config.json`
file (before starting the server):

- `logs`: List of enabled loggers (add "syslog" here)
- `syslog_address`: The address of your remote syslog server which receives the events
- `syslog_facility`: The facility level (see [RFC 3164](https://datatracker.ietf.org/doc/html/rfc3164#section-4.1.1))

Example configuration:
```json
{
  ...,
  "sqlite_file": "",
  "logs": "syslog",
  "syslog_address": "udp://1.2.3.4:514",
  "syslog_facility": 3
}
```

## Development

### Building the Docker image

With the help of Docker `buildx`'s cross-compiling capabilities,
the image can be built for the Raspberry Pi on regular x86 systems.
All you need to do is set the `platform` parameter:

```shell
docker buildx build --platform linux/arm64,linux/amd64 .
```

For this to work, you need to set up a new builder with QEMU once:

1. Install dependencies:

    ```shell
    sudo apt install -y qemu-user-static binfmt-support
    ```

2. Register QEMU with docker:

    ```shell
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    ```

3. Create a new builder for `buildx`:

    ```shell
    docker buildx create --name cross_builder
    docker buildx use cross_builder
    docker buildx inspect --bootstrap
    ```

#### Building the image as `amd64` for local development

To make built images available to a local Docker instance use the `--load` parameter:

```shell
docker buildx build --platform linux/amd64 -t medpot-poc . --load
```

### Testing

A suite of static tests is run with [pre-commit](https://pre-commit.com/).
To install `pre-commit` without superuser permissions we recommend [pipx](https://pipxproject.github.io/pipx/).

```sh
pipx install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg   # Required for the gitlint hook
pre-commit run --all-files                  # Just to test, not actually required
```

Take note of [temporarily disabling hooks](https://pre-commit.com/#temporarily-disabling-hooks).

## Public Funding

![Funded by European Union](https://ec.europa.eu/regional_policy/images/information-sources/logo-download-center/nextgeneu_en.jpg)
