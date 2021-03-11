# [Proca - progressive campaigning](https://proca.foundation) widget

Proca backend is an Elixir app that uses PostgreSQL as data store and RabbitMQ
for data processing. It is the backend / datastore for [proca-widget](https://github.com/fixthestatusquo/proca).

It is made with love, elixir and hope we can change the world for the better.

Please note that this project is released with a [Contributor Code of Conduct](code_of_conduct.md). By participating in this project you agree to abide by its terms.

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md)

# Prerequisites

## PostgreSQL >= 10

## Elixir >= 1.10

[Erlang Solutions](https://www.erlang-solutions.com/downloads/) provides packages and binaries for download.

You'll need the following packages:

erlang erlang-dev erlang-parsetools erlang-xmerl elixir

## RabbitMQ (version?)

## NodeJS (>= 10?) / npm >= 7?

# Development setup

The script utils/configure-development-environment.sh will setup PostgreSQL, the Erlang / Elixir / Pheonix server, the RabbitMQ server and runs npm install in the assets directory.

The script needs a few ENV varaibles set:

`$ export ADMIN_EMAIL=you@example.com MIX_ENV=dev ORGANIZATION='fix-the-status-quo'`

You'll need sudo to run the parts of the script that configure PostgreSQL.

`$ ./utils/configure-development-environment.sh`

The seeds.exs command will print out your login and password:

    #####
    #####   Created Admin user aaron@wemove.eu  #####
    #####   Password: VERY_RANDOM_PASSWORD
    #####

You can then run the development server.

`$ mix phx.server`

By default, the development webserver is located at http://localhost:4000/

# Configuration

See config/config.exs and config/dev.exs for configuration options.
