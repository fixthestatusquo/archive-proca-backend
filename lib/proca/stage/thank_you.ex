defmodule Proca.Stage.ThankYou do
  use Broadway

  alias Broadway.Message
  alias Proca.{Action,Org}

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
        sqs: [
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
      {:ok, %{"actionId" => action_id}} -> message |> prepare(action_id)
      {:error, reason} -> Message.failed(message, reason)
    end
  end

  def prepare(message, action_id) do
    with %Action{} = action <- Action.get_by_id(action_id)
      do
      message
      |> Message.update_data(fn _ -> action end)
      |> Message.put_batch_key(action.action_page.org_id)
      |> Message.put_batcher(:sqs)
      else
        _ -> Message.failed(message, "Can't retireve action")
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
