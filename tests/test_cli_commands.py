import os

import pytest
import redis
import requests
from click.testing import CliRunner

from nyro.cli import cli


@pytest.fixture(autouse=True)
def dummy_env(monkeypatch):
    # Set necessary environment variables for Settings
    monkeypatch.setenv("KV_REST_API_URL", "http://example.com")
    monkeypatch.setenv("KV_REST_API_TOKEN", "token")
    monkeypatch.setenv("REDIS_URL", "redis://localhost:6379/0")


@pytest.fixture()
def runner():
    return CliRunner()


class DummyResponse:
    def __init__(self, text="OK"):
        self.text = text

    def raise_for_status(self):
        pass


def test_set_command(monkeypatch, runner):
    def fake_post(url, headers, json):
        assert url == "http://example.com/set/mykey"
        assert headers["Authorization"] == "Bearer token"
        assert json == {"value": "val"}
        return DummyResponse()

    monkeypatch.setattr(requests, "post", fake_post)
    result = runner.invoke(cli, ["set", "mykey", "val"])
    assert result.exit_code == 0
    assert "OK" in result.output


def test_get_command(monkeypatch, runner):
    def fake_get(url, headers):
        assert url == "http://example.com/get/mykey"
        assert headers["Authorization"] == "Bearer token"
        return DummyResponse(text="VALUE")

    monkeypatch.setattr(requests, "get", fake_get)
    result = runner.invoke(cli, ["get", "mykey"])
    assert result.exit_code == 0
    assert "VALUE" in result.output


def test_del_command(monkeypatch, runner):
    def fake_delete(url, headers):
        assert url == "http://example.com/del/mykey"
        return DummyResponse(text="DELETED")

    monkeypatch.setattr(requests, "delete", fake_delete)
    result = runner.invoke(cli, ["del", "mykey"])
    assert result.exit_code == 0
    assert "DELETED" in result.output


def test_scan_command(monkeypatch, runner):
    def fake_get(url, headers):
        assert url == "http://example.com/scan/0/match/patt/count/50"
        return DummyResponse(text="[]")

    monkeypatch.setenv("KV_REST_API_URL", "http://example.com")
    monkeypatch.setattr(requests, "get", fake_get)
    result = runner.invoke(cli, ["scan", "patt", "--count", "50"])
    assert result.exit_code == 0
    assert "[]" in result.output


def test_lpush_command(monkeypatch, runner):
    def fake_post(url, headers, json):
        assert url == "http://example.com/lpush/mylist"
        assert json == {"element": "item"}
        return DummyResponse(text="1")

    monkeypatch.setattr(requests, "post", fake_post)
    result = runner.invoke(cli, ["lpush", "mylist", "item"])
    assert result.exit_code == 0
    assert "1" in result.output


def test_lrange_command(monkeypatch, runner):
    def fake_get(url, headers):
        assert url == "http://example.com/lrange/mylist/1/3"
        return DummyResponse(text="[\"a\", \"b\"]")

    monkeypatch.setattr(requests, "get", fake_get)
    result = runner.invoke(cli, ["lrange", "mylist", "1", "3"])
    assert result.exit_code == 0
    assert "[" in result.output


def test_stream_add_usage_error(runner):
    result = runner.invoke(cli, ["stream-add", "mystream", "field1"])
    assert result.exit_code != 0
    assert "even number of field/value arguments" in result.output


def test_stream_add_command(monkeypatch, runner):
    class FakeClient:
        def xadd(self, key, data):
            assert key == "str"
            assert data == {"a": "1", "b": "2"}
            return "ID123"

    monkeypatch.setattr(redis, "from_url", lambda url: FakeClient())
    result = runner.invoke(cli, ["stream-add", "str", "a", "1", "b", "2"])
    assert result.exit_code == 0
    assert "ID123" in result.output


def test_stream_add_connection_error(monkeypatch, runner):
    class FakeClient:
        def xadd(self, key, data):
            raise redis.exceptions.ConnectionError("unable to connect")

    monkeypatch.setattr(redis, "from_url", lambda url: FakeClient())
    result = runner.invoke(cli, ["stream-add", "str", "a", "1"])
    assert result.exit_code == 1
    assert "Error connecting to Redis" in result.output


def test_stream_read_command(monkeypatch, runner):
    entries = [(b"1-0", {b"a": b"1"}), (b"2-0", {b"b": b"2"})]

    class FakeClient:
        def xrange(self, key, count):
            assert key == "stream"
            assert count == 2
            return entries

    monkeypatch.setattr(redis, "from_url", lambda url: FakeClient())
    result = runner.invoke(cli, ["stream-read", "stream", "2"])
    assert result.exit_code == 0
    assert "1-0" in result.output
    assert '"a": "1"' in result.output
    assert "2-0" in result.output


def test_stream_read_connection_error(monkeypatch, runner):
    class FakeClient:
        def xrange(self, key, count):
            raise redis.exceptions.ConnectionError("unable to connect")

    monkeypatch.setattr(redis, "from_url", lambda url: FakeClient())
    result = runner.invoke(cli, ["stream-read", "stream", "2"])
    assert result.exit_code == 1
    assert "Error connecting to Redis" in result.output