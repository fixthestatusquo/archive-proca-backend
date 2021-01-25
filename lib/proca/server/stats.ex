defmodule Proca.Server.Stats do
  @moduledoc """
  Stores campaign and action page signature counts in following structure (under campaign state key):
  - map of campaign ids stores 2 element tuple 
  - first element is count for whole campaign
  - second element is a keylist mapping action_type to count

  extra_supporters are included in supoorters count

  TODO: how to add extra_supporters to areas?

  ## State structure:

  interval: int - calculation interval in ms
  query_runs: boolean - a flag saying calculation is running now and we shouldn't run new calculation
  campaign:
  campaign_id ->  (map)
  {deduped supporters, [action_type: count], %{area: count}}
  """

  use GenServer
  alias Proca.{Action, Supporter, ActionPage}
  alias Proca.Repo
  import Ecto.Query

  @impl true
  def init(sync_every_ms) do
    {
      :ok,
      %{
        interval: sync_every_ms,
        campaign: %{},
        query_runs: false
      },
      {:continue, :first_load}
    }
  end

  # Sync counts from DB on every interval

  @impl true
  def handle_continue(:first_load, state) do
    handle_info(:sync, state)
  end

  @impl true
  @doc """
  Every @sync_every_ms ms we send to ourselves a :sync message, to synchronize counts from DB.
  """
  def handle_info(:sync, state) do
    if not state.query_runs do
      me = self()
      Task.start_link(fn -> GenServer.cast(me, {:update_campaigns, calculate()}) end)
    end

    if state.interval > 0 do
      Process.send_after(self(), :sync, state.interval)
    end

    {:noreply, %{state | query_runs: true}}
  end

  # Update state from DB or from increment

  @impl true
  def handle_cast({:update_campaigns, campaign}, state) do
    {:noreply, %{state | campaign: campaign, query_runs: false}}
  end

  @impl true
  def handle_cast(
        {:increment, campaign_id, action_type, area, new_supporter},
        state = %{campaign: campaign}
      ) do

    sup_incr = if(new_supporter, do: 1, else: 0)

    campaign = Map.update(campaign, campaign_id, {0, [], %{}}, 
    fn {sup_ct, types_ct, area_sup} -> 
      {action_type, at_ct} = List.keyfind(types_ct, action_type, 0, {action_type, 0})
      areas = Map.update(area_sup, area, sup_incr, fn c -> c + sup_incr end)

      {
        sup_ct + sup_incr,
        List.keystore(types_ct, action_type, 0, {action_type, at_ct + 1}),
        areas
      }
    end)


    {:noreply, %{state | campaign: campaign}}
  end

  @impl true
  @doc """
  - Get stats for campaign
  - Get stats for action types
  """
  def handle_call({:stats, c_id}, _f, stats = %{campaign: camp}) do
    cst = Map.get(camp, c_id, {0, [], %{}})

    {:reply, cst, stats}
  end

  def calculate() do
    # Calculation of supporters:
    # We can have many supporters records for same fingerprint.
    # We want to use only last one per each campaign.
    # We use ORDER + SELECT DISTINCT() to make the DB select such last records
    # When we calculate areas for campaign, we also do this, so if someone signed from two areas, only last one 
    # is counted (within scope of campaign)

    first_supporter_query = 
      from(s in Supporter, order_by: s.inserted_at)
      |> where([s], s.processing_status in [:accepted, :delivered])
      |> distinct([s], s.fingerprint)

    all_supporters_query = 
      first_supporter_query
      |> subquery()
      |> group_by([s], [s.campaign_id])
      |> select([s], [s.campaign_id, count(s.fingerprint)])

    supporters =
      all_supporters_query
      |> Repo.all()
      |> Enum.reduce(%{}, fn [c_id, sup_ct], acc -> Map.put(acc, c_id, {sup_ct, [], %{}}) end)

    area_supporters_query = first_supporter_query
      |> where([s], not is_nil(s.area))
      |> subquery()
      |> group_by([s], [s.campaign_id, s.area])
      |> select([s], [s.campaign_id, s.area, count(s.fingerprint)])

    area_supporters =
      area_supporters_query
      |> Repo.all()
      |> Enum.reduce(supporters, fn [c_id, area, ar_sup], acc -> 
        Map.update(
          acc, 
          c_id, 
          {0, [], %{ area => ar_sup }},
          fn {s, a, area_map} -> {s, a, Map.put(area_map, area, ar_sup)} end) 
      end)

    extra_supporters =
      from(ap in ActionPage,
        group_by: ap.campaign_id,
        where: ap.extra_supporters != 0,
        select: [ap.campaign_id, sum(ap.extra_supporters)]
      )
      |> Repo.all()
      |> Enum.map(fn [c_id, ex_ct] -> {c_id, ex_ct} end)
      |> Map.new

    # merge supporters and extra_supporters

    action_counts =
      from(a in Action,
        where: a.processing_status in [:accepted, :delivered],
        group_by: [a.campaign_id, a.action_type],
        select: [a.campaign_id, a.action_type, count(a.id)]
      )
      |> Repo.all()
      |> Enum.reduce(%{}, &add_action_type_counts/2)

    area_supporters
    |> Enum.reduce(%{}, fn {campaign_id, {supporters, [], supporters_by_area}}, acc -> 
      supporters_plus_extras = supporters + Map.get(extra_supporters, campaign_id, 0)
      acc |> Map.put(campaign_id, {
        supporters_plus_extras,
        action_counts |> Map.get(campaign_id, []),
        supporters_by_area
      })
    end)
  end

  defp add_action_type_counts([c_id, at, ct], acc) do
    Map.update(acc, c_id, [{at, ct}], fn lst -> 
      List.keystore(lst, at, 0, {at, ct})
    end)
  end

  # Client side
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def stats(campaign_id) do
    GenServer.call(__MODULE__, {:stats, campaign_id})
  end

  def increment(campaign_id, action_type, new_supporter) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, action_type, nil, new_supporter})
  end

  def increment(campaign_id, action_type, area, new_supporter) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, action_type, area, new_supporter})
  end
end
