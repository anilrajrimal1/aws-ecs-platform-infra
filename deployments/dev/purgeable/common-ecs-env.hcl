locals {
  envs = {
    ENKETO_BASE_URL = get_env("ENKETO_BASE_URL", "http://enketo.ff-dev.internal:8005/-")
  }
}
