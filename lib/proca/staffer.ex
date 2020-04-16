defmodule Proca.Staffer do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.Repo
  alias Proca.Users.User
  alias Proca.Staffer

  schema "staffers" do
    field :perms, :integer
    field :last_signin_at, :utc_datetime
    belongs_to :org, Proca.Org
    belongs_to :user, Proca.Users.User

    timestamps()
  end

  @doc false
  def changeset(staffer, attrs) do
    staffer
    |> cast(attrs, [:perms, :last_signin_at])
    |> validate_required([:perms])
  end

  def for_user_in_org(%User{id: id}, org_name) when is_binary(org_name) do
    from(s in Staffer,
      join: o in assoc(s, :org),
      where: s.user_id == ^id and o.name == ^org_name,
      preload: [org: o])
    |> Repo.one
  end

  def for_user_in_org(%User{id: id}, org_id) when is_integer(org_id) do
    from(s in Staffer,
      join: o in assoc(s, :org),
      where: s.user_id == ^id and o.id == ^org_id,
      preload: [org: o])
      |> Repo.one
  end


  def for_user(%User{id: id}) do
    from(s in Staffer,
      join: o in assoc(s, :org),
      where: s.user_id == ^id,
      order_by: [desc: :last_signin_at],
      preload: [org: o],
      limit: 1
    )
    |> Repo.one
  end
end