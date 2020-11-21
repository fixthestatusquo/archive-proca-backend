defmodule ProcaWeb.Resolvers.Org do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query
  import Ecto.Changeset

  alias Proca.{ActionPage, Campaign}
  alias Proca.{Org, Staffer, PublicKey}
  alias ProcaWeb.Helper
  alias Ecto.Multi

  alias Proca.Repo
  import Proca.Staffer.Permission

  def get_by_name(_, %{name: name}, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(name, [[campaigns: :org], :action_pages]),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
         true <- can?(s, :use_api) do
      {:ok, org}
    else
      _ -> {:error, "Access forbidden"}
    end
  end

  def campaign_by_id(org, %{id: camp_id}, _) do
    c =
      Campaign.select_by_org(org)
      |> where([c], c.id == ^camp_id)
      |> Repo.one()

    case c do
      nil -> {:error, "not_found"}
      c -> {:ok, c}
    end
  end

  def campaigns(org, _, _) do
    cl =
      Campaign.select_by_org(org)
      |> preload([c], [:org])
      |> Repo.all()

    {:ok, cl}
  end

  def action_pages(org, _, _) do
    c = Ecto.assoc(org, :action_pages)
    |> preload([ap], [:org])
    |> Repo.all

    {:ok, c}
  end

  def action_page(%{id: org_id}, params, _) do
    case ProcaWeb.Resolvers.ActionPage.find(nil, params, nil) do
      {:ok, %ActionPage{org_id: ^org_id}} = ret ->
        ret

      {:ok, %ActionPage{}} ->
        {:error,
         %{
           message: "Action page not found",
           extensions: %{code: "not_found"}
         }}

      {:error, x} ->
        {:error, x}
    end
  end

  def org_personal_data(org, _args, _ctx) do
    {
      :ok,
      %{
        contact_schema: org.contact_schema,
        email_opt_in: org.email_opt_in,
        email_opt_in_template: org.email_opt_in_template
      }
    }
  end

  def add_org(_, params, %{context: %{user: user}}) do
    with {:ok, org} <- Org.changeset(%Org{}, params) |> Repo.insert(),
         perms <- Staffer.Permission.add(0, Staffer.Role.permissions(:owner)),
         {:ok, staffer} <- Staffer.build_for(user, org.id, perms) |> Repo.insert()
      do
      {:ok, org}
    else
      {:error, changeset} -> Helper.format_errors(changeset)
    end
  end

  def delete_org(_, _, %{context: %{org: org}}) do
    case Repo.delete(org) do
      {:ok, _} -> {:ok, true}
      {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def update_org(_p, %{name: name} = attrs, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(name),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
         true <- can?(s, :use_api) do
      Org.changeset(org, attrs)
      |> Repo.update()
    else
      _ -> {:error, "Access forbidden"}
    end
  end

  def list_keys(%{id: org_id}, _, %{context: %{user: user}}) do
    with %Staffer{} = s <- Staffer.for_user_in_org(user, org_id),
         true <- can?(s, [:use_api, :export_contacts]) do
      {
        :ok,
        from(pk in PublicKey,
          where: pk.org_id == ^org_id,
          select: %{id: pk.id,
                    name: pk.name,
                    public: pk.public,
                    active: pk.active,
                    expired: pk.expired,
                    updated_at: pk.updated_at}
        )
        |> Repo.all()
        |> Enum.map(fn pk ->
          pk
          |> Map.put(:public, PublicKey.base_encode(pk.public))
          |> Map.put(:exired_at, if pk.expired do pk.updated_at else nil end)
          end)
      }
    else
      _ -> {:error, "Access forbidden"}
    end
  end

  def add_key(_, %{name: name, private: private}, %{context: %{org: org}}) do
    with ch = %{valid?: true} <- PublicKey.import_private_for(org, private, name),
         {:ok, key} <- Repo.insert(ch)
      do
        {:ok, key}
      else
        ch = %{valid?: false} -> {:error, Helper.format_errors(ch)}
        {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def generate_key(_, %{name: name}, %{context: %{org: org}}) do

    with pk = %{valid?: true} <- PublicKey.build_for(org, name),
         {:ok, _pub_pk} <- change(pk, private: nil) |> Repo.insert()
      do
      {:ok, pk}
      else
        ch = %{valid?: false} -> {:error, Helper.format_errors(ch)}
        {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def activate_key(_, %{id: id}, %{context: %{org: org}}) do
    now = DateTime.utc_now()

    case Multi.new()
    |> Multi.run(:pk, fn _, _ ->
      case Repo.get_by PublicKey, id: id, org_id: org.id do
        nil ->
          {:error, %{
              message: "Public key not found",
              extensions: %{code: "not_found"}
           }}
        pk ->
          change(pk, expired_at: nil)
          |> Repo.insert()
      end
    end)
    |> Multi.run(:other, fn _, %{pk: pk} ->
      Repo.update_all(
        from(k in PublicKey, where: k.org_id == ^org.id and k.id != ^pk.id),
        set: [expired_at: now]
      )
    end)
    |> Repo.transaction() do
     {:ok, %{pk: pk}} -> {:ok, pk}
     {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
       {:error, Helper.format_errors(changeset)}
    end
  end
end
