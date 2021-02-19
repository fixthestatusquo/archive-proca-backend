defmodule Proca.Server.Notify do
  @moduledoc """
  Server that decides what actions should be done after different events
  """
  alias Proca.Repo
  alias Proca.{Action, Supporter, Org, PublicKey}

  @spec action_created(%Action{}, %Supporter{} | nil) :: :ok
  def action_created(action, supporter \\ nil) do
    increment_counter(action, supporter)
    process_action(action)
    :ok
  end

  @spec public_key_created(Org, PublicKey) :: :ok
  def public_key_created(org, key) do
    :ok
  end

  @spec public_key_activated(Org, PublicKey) :: :ok
  def public_key_activated(org, key) do
    Proca.Server.Keys.update_key(org, key)
  end

  def action_page_added(action_page) do
    action_page_updated(action_page)
  end

  def action_page_updated(action_page) do
    action_page = Repo.preload(action_page, [:org, :campaign])
    publish_subscription_event(action_page, action_page_upserted: "$instance")
    if not is_nil(action_page.org) do
      publish_subscription_event(action_page, action_page_upserted: action_page.org.name)
    end
    :ok
  end

  # common side-effects

  defp process_action(action) do
    Proca.Server.Processing.process_async(action)
  end

  defp increment_counter(%Action{campaign_id: cid, action_page: %{org_id: org_id}, action_type: atype}, nil) do
    Proca.Server.Stats.increment(cid, org_id, atype, nil, false)
  end

  defp increment_counter(%Action{campaign_id: cid, action_page: %{org_id: org_id}, action_type: atype}, %Supporter{area: area}) do
    Proca.Server.Stats.increment(cid, org_id, atype, area, true)
  end


  defp publish_subscription_event(record, routing_key) do
    Absinthe.Subscription.publish(ProcaWeb.Endpoint, record, routing_key)
  end
end
