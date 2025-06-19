import os

import pytest
from click.testing import CliRunner

from nyro.cli import cli


@pytest.fixture()
def runner():
    return CliRunner()


def test_init_creates_env(runner):
    example = "FOO=bar"
    with runner.isolated_filesystem():
        with open('.env.example', 'w') as f:
            f.write(example)
        result = runner.invoke(cli, ['init'])
        assert result.exit_code == 0
        assert 'Created .env from .env.example' in result.output
        with open('.env', 'r') as f:
            assert f.read() == example


def test_init_fails_if_exists(runner):
    with runner.isolated_filesystem():
        open('.env.example', 'w').write('X=1')
        open('.env', 'w').write('OLD')
        result = runner.invoke(cli, ['init'])
        assert result.exit_code != 0
        assert '.env already exists' in result.output


def test_init_force_overwrite(runner):
    with runner.isolated_filesystem():
        open('.env.example', 'w').write('NEW')
        open('.env', 'w').write('OLD')
        result = runner.invoke(cli, ['init', '--force'])
        assert result.exit_code == 0
        with open('.env', 'r') as f:
            assert f.read() == 'NEW'


def test_init_source_missing(runner):
    with runner.isolated_filesystem():
        result = runner.invoke(cli, ['init'])
        assert result.exit_code != 0
        assert 'Source .env.example not found.' in result.output