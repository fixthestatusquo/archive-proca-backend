defmodule Proca.Server.Processing do
  use GenServer
  alias Proca.Repo
  alias Proca.{Action, ActionPage, Supporter}
  alias Proca.Server.Plumbing
  import Ecto.Changeset

  @moduledoc """
  Processing:
  1. We receive Actions with Supporter or with unbound ref.
  2. Action with supporter may have new or resolved supporter (by ref)
  3. Action with unbound ref will be bound later () 

  So:
  1. Process supporter, then action
  2. Process supporter
  3. ignore. This is a case where we store action for counts (share, tweet
  without any contact, and it might never arrive). On the other hand, it would be nice to have this later in CRM right? 

       [ A(NEW) / nil ]
          | linked?
          v
       [ A(NEW) / S(NEW) ]           <-----.
          |                                |  On new action bound to rejected contact
          v                                |  Do we reset?
       [ A(NEW) / S(CONFIRMING)] -> [ A(REJECTED) / S(REJECTED) ]   - - - > (remove the cookie?!)
          |
          v
    ,->[ A(NEW) / S(ACCEPTED)]
    |     |
  n |     v
  e |  [ A(CONFIRMING) / S(ACCEPTED)] -> [ A(REJECTED) / S(ACCEPTED)] --> x
  w |     |
    |     v
    `--[ A(ACCEPTED) / S(ACCEPTED)] -> [ A(DELIVERED) / S(ACCEPTED)]

  This mechanism is supposed to be able to run many times with same result if
  action and supporter bits do not change.

  We need:
  - supporter.confirming
  - supporter.confirmed
  - action.confirming
  - action.confirmed
  - action.delivered

  XXX for starters, we assume:
  ActionPage does not require Supporter confirmation, supporter :new -> :accepted
  ActionPage does not require Action confirmation, goes from :new -> :accepted
  But it is pushed to delivery queue and chnaged to :delivered (after processing in Broadway?)
  """

  @impl true
  def init([]) do
    {:ok, []}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def handle_cast({:action, action}, state) do
    process(action)
    {:noreply, state}
  end

  def process_async(action) do
    GenServer.cast(__MODULE__, {:action, action})
  end

  @doc """
  This function implements the state machine for Action. It returns a changeset to update action/supporter (state) and atoms telling where to route action.
  """
  @spec transition(Action, ActionPage) :: {Ecto.Changeset, :action | :supporter, :confirm | :deliver} | :ok
  def transition(%{
        processing_status: :new,
        supporter: nil
                 }, _ap) do
    # Action without any supporter associated: not processing.
    :ok
  end
  
  def transition(%{
        processing_status: :delivered,
        supporter: %{processing_status: :accepted}
        }, _ap) do
    # Action already delivered: not processing.
    :ok
  end

  def transition(action = %{
        processing_status: :new,
        supporter: %{processing_status: :accepted}
                 }, _ap) do

    # go strainght to delivered
    {
      change_status(action, :delivered, :accepted),
      :action,
      :deliver
    }
  end

  def transition(action = %{
        processing_status: :new,
        supporter: %{processing_status: :new}
                 }, _ap) do
    # we should handle confirmation if required, but before it's implemented let's accept supporter
    # and instantly go to delivery
    {
      change_status(action, :delivered, :accepted),
      :action,
      :deliver
    }
  end

  def change_status(action, action_status, supporter_status) do
    sup = change(action.supporter, processing_status: supporter_status)
    change(action, processing_status: action_status, supporter: sup)
  end

  @doc """
  This method emits an effect on transition.
  """
  @spec emit(Action, :action | :supporter, :confirm | :deliver) :: :ok | :error
  def emit(action, :action, :deliver) do
    Plumbing.push(
      exchange_for(:action, :deliver),
      "#{action.action_page.org.name}.system.action",
      system_action_data(action)
    )
  end

  def exchange_for(_, :confirm) do
    "confirm"
  end

  def exchange_for(_, :deliver) do
    "deliver"
  end

  @doc "We just pass action id around because we can just retrieve the action and have a synced copy"
  def system_action_data(action) do
    %{
      "actionId" => action.id,
    }
  end

  @spec process(Action) :: :ok
  def process(action) do
    action = Repo.preload(action, [action_page: :org, supporter: :contacts])
    case transition(action, action.action_page) do
      {state_change, thing, stage} ->
        Repo.transaction(fn ->
          case emit(action, thing, stage) do
            :ok ->
              Repo.update!(state_change)
              :ok
            :error -> raise "Cannot emit"
          end
        end)
      :ok -> :ok
    end
  end
end
