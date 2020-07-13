defmodule Proca.ActionPage do
  @moduledoc """
  Action Page belongs to a Campaign, and reprezents a page (widget) where members take action.

  Action Page accepts data in many formats (See Contact.Data) and produces Contact and Supporter records.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Proca.Repo
  alias Proca.{ActionPage, Campaign, Org, Contact, Supporter}

  schema "action_pages" do
    field :locale, :string
    field :url, :string
    field :delivery, :boolean

    belongs_to :campaign, Proca.Campaign
    belongs_to :org, Proca.Org

    field :extra_supporters, :integer, default: 0

    field :thank_you_template_ref, :string

    timestamps()
  end

  @doc false
  def changeset(action_page, attrs) do
    action_page
    |> cast(attrs, [:url, :locale, :org_id, :delivery, :extra_supporters])
    |> validate_required([:url, :locale, :org_id])
    |> validate_format(:url, ~r/^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+/) 
  end

  def upsert(org, campaign, attrs) do
    (Repo.get_by(ActionPage, campaign_id: campaign.id, url: attrs.url) || %ActionPage{})
    |> cast(attrs, [:url, :locale, :extra_supporters, :delivery, :thank_you_template_ref])
    |> validate_required([:url, :locale])
    |> validate_format(:url, ~r/^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+/) 
    |> put_change(:campaign_id, campaign.id)
    |> put_change(:org_id, org.id)
  end

  def changeset(attrs) do
    changeset(%ActionPage{}, attrs)
  end

  def find(id) do
    Repo.one from a in ActionPage, where: a.id == ^id, preload: [:campaign, :org]
  end

  def contact_schema(%ActionPage{campaign: %Campaign{org: %Org{contact_schema: cs}}}) do
    case cs do
      :basic -> Proca.Contact.BasicData
      :popular_initiative -> Proca.Contact.PopularInitiativeData
    end
  end

  def new_data(params, action_page) do
    schema = contact_schema(action_page)
    apply(schema, :from_input, [params])
  end

  @spec new_contact(struct(), ActionPage) :: {Ecto.Changeset.t(Contact), string()}
  def new_contact(data, action_page) do
    schema = contact_schema(action_page)
    apply(schema, :to_contact, [data, action_page])
  end

  @spec new_supporter(struct(), ActionPage) :: Ecto.Changeset.t(Supporter)
  def new_supporter(data, action_page) do
    %Supporter{}
    |> cast(Map.from_struct(data), [:first_name, :email])  ## <- this list must come from action page pipeline needs
    |> put_assoc(:campaign, action_page.campaign)
    |> put_assoc(:action_page, action_page)
  end
end
