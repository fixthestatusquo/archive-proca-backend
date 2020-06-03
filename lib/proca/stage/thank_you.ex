defmodule Proca.Stage.ThankYou do
  use Broadway

  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
                 queue: "system.email.thankyou",
                 connection: Proca.Server.Plumbing.connection_url(),
                 qos: [
                   prefetch_count: 10,
                 ]
                },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ],
      batchers: [
        default: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 1
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, %Message{data: data} = message, _) do
    case JSON.decode(data) do
      {:ok, %{"actionId" => action_id}} -> message
      {:error, reason} -> Message.failed(message, reason)
    end
  end

  @impl true
  def handle_batch(key, messages, batch_info, _) do
    IO.inspect(key, label: "batch key")
    IO.inspect(messages, label: "batch messages")
    IO.inspect(batch_info, label: "batch info")
    messages
  end



end
