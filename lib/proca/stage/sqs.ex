defmodule Proca.Stage.SQS do
  use Broadway

  alias Broadway.Message
  alias Proca.{Action,Org}
  import Ecto.Query, only: [from: 2]


  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
                 queue: "system.sqs",
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
        sqs: [
          batch_size: 10,
          batch_timeout: 10_000,
          concurrency: 1
        ]
      ]
    )
  end


  @impl true
  def handle_message(_, %Message{data: data} = message, _) do
    case JSON.decode(data) do
      {:ok, %{"orgId" => org_id} = action} ->
        message
        |> Message.update_data(fn _ -> action end)
        |> Message.put_batch_key(org_id)
        |> Message.put_batcher(:sqs)
      {:error, reason} -> Message.failed(message, reason)
    end
  end


  @impl true
  def handle_batch(org_id, msgs, batch_info, _) do

  end
end
