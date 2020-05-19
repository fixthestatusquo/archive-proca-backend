defmodule Proca.Server.Plumbing do
  use GenServer

  @moduledoc """
  Plumbing server is responsible for setting up the signature processing in Proca.

  # How does this work?

  Proca uses RabbitMQ queues and Broadway to process signatures, while updating
  the record to mark that it was processed in each stage.

  ## Processing dynamics

  1. Different orgs processing should not clog one anothers queues, so every org
  needs at least its own set of queues.

  2. 

  ## Stages:

  ```
  Signature -> (__DB__)
  `---> [ confirm queue ]

  ```

  """

  @impl true
  def init(url) do
    {:ok, %{conn: nil, url: url}, {:continue, :connect}}
  end

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: __MODULE__)
  end

  @impl true
  def handle_continue(:connect, st) do
    with {:ok, c} <- AMQP.Connection.open(st.url) do
      # inform us when AMQP connection is down
      Process.monitor(c.pid)
      
      {
        :noreply,
        %{st | conn: c}
      }
    else
      {:error, reason} -> {:stop, reason, st}
    end
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, reason}, %{conn: %{ pid: pid }}) do
    # Stop GenServer. Will be restarted by Supervisor.
    {:stop, {:connection_lost, reason}, nil}
  end

  @impl true
  def handle_call(:state, _from, st) do
    {:reply,
     st,
     st
    }
  end

end
