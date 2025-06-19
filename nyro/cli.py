import json
import os
import requests
import shutil
import sys

import click
import redis

from nyro.config import Settings



@click.group()
def cli():
    """
    Nyro CLI: AI phase navigator and recursive guide.

    Commands are invoked as subcommands (no leading dashes), for example:
      nyro set <key> <value>
      nyro get <key>
      nyro stream-add <stream_key> <field1> <value1> [<field2> <value2>...]
      nyro init        # bootstrap .env from .env.example for your credentials

    Use `nyro init` to create a local .env file for your REDIS_URL and REST API tokens.
    """
    pass


@cli.command()
@click.argument("key")
@click.argument("value")
def set(key, value):
    """Set a key to a value."""
    settings = Settings()
    url = f"{settings.kv_rest_api_url}/set/{key}"
    headers = {
        "Authorization": f"Bearer {settings.kv_rest_api_token}",
        "Content-Type": "application/json",
    }
    resp = requests.post(url, headers=headers, json={"value": value})
    resp.raise_for_status()
    click.echo(resp.text)


@cli.command(name="get")
@click.argument("key")
def get_cmd(key):
    """Get the value of a key."""
    settings = Settings()
    url = f"{settings.kv_rest_api_url}/get/{key}"
    headers = {"Authorization": f"Bearer {settings.kv_rest_api_token}"}
    resp = requests.get(url, headers=headers)
    resp.raise_for_status()
    click.echo(resp.text)


@cli.command(name="del")
@click.argument("key")
def del_cmd(key):
    """Delete a key."""
    settings = Settings()
    url = f"{settings.kv_rest_api_url}/del/{key}"
    headers = {"Authorization": f"Bearer {settings.kv_rest_api_token}"}
    resp = requests.delete(url, headers=headers)
    resp.raise_for_status()
    click.echo(resp.text)


@cli.command()
@click.argument("pattern")
@click.option("--count", default=100, help="Maximum number of keys to return.")
def scan(pattern, count):
    """Scan keys matching a pattern."""
    settings = Settings()
    url = f"{settings.kv_rest_api_url}/scan/0/match/{pattern}/count/{count}"
    headers = {"Authorization": f"Bearer {settings.kv_rest_api_token}"}
    resp = requests.get(url, headers=headers)
    resp.raise_for_status()
    click.echo(resp.text)


@cli.command(name="lpush")
@click.argument("list_name")
@click.argument("element")
def lpush(list_name, element):
    """Push an element onto a list."""
    settings = Settings()
    url = f"{settings.kv_rest_api_url}/lpush/{list_name}"
    headers = {
        "Authorization": f"Bearer {settings.kv_rest_api_token}",
        "Content-Type": "application/json",
    }
    resp = requests.post(url, headers=headers, json={"element": element})
    resp.raise_for_status()
    click.echo(resp.text)


@cli.command(name="lrange")
@click.argument("list_name")
@click.argument("start", type=int, default=0)
@click.argument("stop", type=int, default=10)
def lrange(list_name, start, stop):
    """Get a range of elements from a list."""
    settings = Settings()
    url = f"{settings.kv_rest_api_url}/lrange/{list_name}/{start}/{stop}"
    headers = {"Authorization": f"Bearer {settings.kv_rest_api_token}"}
    resp = requests.get(url, headers=headers)
    resp.raise_for_status()
    click.echo(resp.text)


@cli.command(name="stream-add")
@click.argument("stream_key")
@click.argument("fieldvals", nargs=-1)
def stream_add(stream_key, fieldvals):
    """Add entries to a Redis stream."""
    if len(fieldvals) % 2 != 0:
        raise click.UsageError(
            "STREAM-ADD requires an even number of field/value arguments"
        )
    settings = Settings()
    client = redis.from_url(settings.redis_url)
    data = dict(zip(fieldvals[0::2], fieldvals[1::2]))
    try:
        entry_id = client.xadd(stream_key, data)
    except redis.exceptions.ConnectionError as e:
        click.echo(
            f"Error connecting to Redis at '{settings.redis_url}': {e}", err=True
        )
        sys.exit(1)
    click.echo(entry_id)


@cli.command(name="stream-read")
@click.argument("stream_key")
@click.argument("count", type=click.IntRange(min=1), default=10)
def stream_read(stream_key, count):
    """Read entries from a Redis stream.
    
    Args:
        stream_key: The name of the stream to read from
        count: Number of entries to read (must be positive)
    """
    settings = Settings()
    client = redis.from_url(settings.redis_url)
    try:
        entries = client.xrange(stream_key, count=count)
        if not entries:
            click.echo("No entries found in stream")
            return
    except redis.exceptions.ConnectionError as e:
        click.echo(
            f"Error connecting to Redis at '{settings.redis_url}': {e}", err=True
        )
        sys.exit(1)
    for entry_id, fields in entries:
        decoded = {k.decode(): v.decode() for k, v in fields.items()}
        click.echo(f"{entry_id.decode()}: {json.dumps(decoded)}")


@cli.command(name="init")
@click.option("--force", "-f", is_flag=True, help="Overwrite existing .env if it exists.")
def init(force):
    """Create a .env file from the .env.example template."""
    src = ".env.example"
    dst = ".env"
    if os.path.exists(dst) and not force:
        click.echo(f"{dst} already exists. Use --force to overwrite.", err=True)
        sys.exit(1)
    try:
        shutil.copyfile(src, dst)
    except FileNotFoundError:
        click.echo(f"Source {src} not found.", err=True)
        sys.exit(1)
    click.echo(f"Created {dst} from {src}")

if __name__ == "__main__":
    cli()