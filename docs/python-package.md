# Python Package & CLI Usage

This document describes how to install and use the nyro Python package.

## Installation

Install nyro from PyPI:

```bash
pip install nyro
```

Or install from source for development:

```bash
git clone <repo-url>
cd nyro
pip install -e .
```

## Using the CLI

Once installed, the `nyro` CLI is available:

```bash
$ nyro --help
```

You will see commands:

```bash
Usage: nyro [OPTIONS] COMMAND [ARGS]...

Options:
  --help  Show this message and exit.

Commands:
  set     Set a key to a value.
  get     Get the value of a key.
  del     Delete a key.
  scan    Scan keys matching a pattern.
  stream  Read entries from a Redis stream.
```

For detailed CLI tutorials, see the courses/python notebooks.
### Example: Adding to a Redis stream

```bash
# Use subcommands (no leading dashes) and supply your field/value pairs:
nyro stream-add mystream temperature 23.5 humidity 65
```

## Initializing your environment

Before running Nyro commands, create a `.env` file with your credentials:

```bash
nyro init        # copies .env.example → .env
nyro init --force  # overwrite existing .env
```