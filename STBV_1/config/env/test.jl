using Genie, Logging

Genie.Configuration.config!(
  server_port                     = 8021,
  server_host                     = "stb-local",
  log_level                       = Logging.Debug,
  log_to_file                     = true,
  server_handle_static_files      = true
)

ENV["JULIA_REVISE"] = "off"
