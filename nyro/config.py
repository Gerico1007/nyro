import json


from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    """
    Configuration settings read from environment or .env file.
    """
    kv_rest_api_url: str = Field(..., env="KV_REST_API_URL")
    kv_rest_api_token: str = Field(..., env="KV_REST_API_TOKEN")
    kv_rest_api_read_only_token: str | None = Field(None, env="KV_REST_API_READ_ONLY_TOKEN")
    redis_url: str = Field(..., env="REDIS_URL")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )