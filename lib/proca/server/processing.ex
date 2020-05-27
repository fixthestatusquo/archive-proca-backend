defmodule Proca.Server.Processing do
  alias Proca.Repo
  alias Proca.{Action, ActionPage, Supporter}

  @impl true
  def handle_cast({:action, a}, state) do
    # We have action with or without supporter
  end

  @doc """
  Processing:
  1. We receive Actions with Supporter or with unbound ref.
  2. Action with supporter may have new or resolved supporter (by ref)
  3. Action with unbound ref will be bound later () 

  So:
  1. Process supporter, then action
  2. Process supporter
  3. ignore. This is a case where we store action for counts (share, tweet
  without any contact, and it might never arrive). On the other hand, it would be nice to have this later in CRM right? 

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

  """
  @spec process(Action, ActionPage) :: {:confirm | :deliver, :action | :supporter} | :ok
  def process(a, ap) do
    cond do
      has_supporter(a) && confirm_supporter(a, ap) -> {:confirm, :supporter}
      confirm_action(a, ap) -> {:confirm, :action}
      deliver_action(a, ap) -> {:deliver, :action}
      true -> :ok
    end
  end

  defp has_supporter(_a) do
    false
  end

  defp confirm_supporter(_a, _ap) do
    true
  end

  defp confirm_action(_a, _ap) do
    true
  end

  defp deliver_action(_a, _ap) do
    true
  end

end
