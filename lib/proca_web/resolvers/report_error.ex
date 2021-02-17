defmodule ProcaWeb.Resolvers.ReportError do 
  @behaviour Absinthe.Middleware

  def call(%Absinthe.Resolution{
    state: :resolved,
    errors: [_|_]
    } = resolution, _)  do 
      if enabled? do
        try do 
          info = %{
            path: Enum.map(resolution.path, &Map.get(&1, :name)),
            extensions: resolution.extensions,
            errors: resolution.errors,
            user: get_in(resolution.context, [:user, :email]),
            org: get_in(resolution.context, [:org, :name]),
            campaign: get_in(resolution.context, [:campaign, :name]),
            name: get_in(resolution.arguments, [:name]),
            id: get_in(resolution.arguments, [:id])
          }
          event = "error." <> (info.path |> Enum.join("."))

          Sentry.capture_message(event, extra: info)
        rescue 
          e in RuntimeError -> 
            Sentry.capture_message("error.error", extra: %{exception: Map.get(e, :message, "(no message)")})
        end
      end
    resolution
  end

  def enabled? do
    not is_nil Sentry.Config.dsn
  end

  def call(reso, _) do 
    reso 
  end

  def scrub_params(conn) do
    # Makes use of the default body_scrubber to avoid sending password
    # and credit card information in plain text.  To also prevent sending
    # our sensitive "my_secret_field" and "other_sensitive_data" fields,
    # we simply drop those keys.
    Sentry.PlugContext.default_body_scrubber(conn)
    |> Map.drop(["query", "variables"])
  end

  def scrub_headers(conn) do
    # default is: Sentry.Plug.default_header_scrubber(conn)
    #
    # We do not want to include Content-Type or User-Agent in reported
    # headers, so we drop them.
    Enum.into(conn.req_headers, %{})
    |> Map.drop(["X-Forwarded-For", "X-Real-Ip"])
  end
end
