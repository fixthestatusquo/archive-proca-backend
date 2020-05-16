defmodule Proca.Supporter do
  use Ecto.Schema
  alias Proca.Repo
  alias Proca.{Org, Consent, Supporter, Contact, ActionPage}
  import Ecto.Changeset
  import Ecto.Query

  schema "supporters" do
    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source

    many_to_many(
      :contacts,
      Proca.Contact,
      join_through: "supporter_contacts",
      on_replace: :delete
    )

    field :fingerprint, :binary
    has_many :actions, Proca.Action

    timestamps()
  end

  @doc false
  def changeset(supporter, attrs) do
    supporter
    |> cast(attrs, [])
    |> validate_required([])
  end

  def maybe_encrypt(contact, [pk]) do
    Contact.encrypt(contact, [pk])
  end

  def maybe_encrypt(contact, []) do
    [contact]
  end

  def distribute_personal_data(contact, action_page, consents) do
    # could be 2 consents here for AP and Camp owners...
    with keys <- Org.get_public_keys(action_page.org) |> Org.active_public_keys(),
         [cch] <- maybe_encrypt(contact, keys),
         cons <- Consent.from_opt_in(consents.opt_in),
         cch2 <- put_assoc(cch, :consent, cons) do
      changeset(%Supporter{}, %{})
      |> put_assoc(:campaign, action_page.campaign)
      |> put_assoc(:action_page, action_page)
      |> put_assoc(:contacts, [cch2])
    end
  end

  def create_supporter(action_page, %{contact: contact, privacy: cons}) do
    data_mod = ActionPage.data_module(action_page)

    case apply(data_mod, :from_input, [contact]) do
      %{valid?: true} = data ->
        with contact = %{valid?: true} <- apply(data_mod, :to_contact, [data, action_page]),
             sup = %{valid?: true} <- distribute_personal_data(contact, action_page, cons),
             sup_fpr = %{valid?: true} <- apply(data_mod, :add_fingerprint, [sup, data]) do
          sup_fpr
        else
          invalid_data ->
            {:error, invalid_data}
        end

      %{valid?: false} = invalid_data ->
        {:error, invalid_data}
    end
  end

  # XXX this should return supporter for all organisation, not just campaign,
  # because user could save a cookie on one campaign, and then one-click sign
  # should be able to reach the supporter record. This should not, however,
  # reach other orgs supporters
  @doc "Returns %Supporter{} or nil"
  def find_by_fingerprint(fingerprint, campaign_id) do
    query =
      from(s in Supporter,
        where: s.campaign_id == ^campaign_id and s.fingerprint == ^fingerprint,
        order_by: [desc: :inserted_at],
        limit: 1,
        preload: [:contacts]
      )

    Repo.one(query)
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end
end
