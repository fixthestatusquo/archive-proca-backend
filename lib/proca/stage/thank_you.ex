defmodule Proca.Stage.ThankYou do
  use Broadway

  # alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: MyBroadway,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
                 queue: "sys.email.thankyou",
                 connection: Proca.Server.Plumging.connection_url,
                 qos: [
                   prefetch_count: 10,
                 ]
                },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 50
        ]
      ],
      batchers: [
        default: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 2
        ]
      ]
    )
  end



end
