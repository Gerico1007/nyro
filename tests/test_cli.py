import os
import sys
import pytest
from click.testing import CliRunner

# Ensure project root is on PYTHONPATH for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from nyro.cli import cli


def test_cli_help():
    runner = CliRunner()
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage" in result.output