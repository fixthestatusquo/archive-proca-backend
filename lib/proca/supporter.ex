defmodule Proca.Supporter do
  use Ecto.Schema
  alias Proca.Repo
  alias Proca.{Supporter, Contact, ActionPage}
  import Ecto.Changeset
  import Ecto.Query

  schema "supporters" do
    has_many :contacts, Proca.Contact

    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source

    field :fingerprint, :binary
    has_many :actions, Proca.Action

    field :first_name, :string
    field :email, :string

    field :processing_status, ProcessingStatus, default: :new

    timestamps()
  end

  @doc false
  def changeset(supporter, attrs) do
    supporter
    |> cast(attrs, [])
    |> validate_required([])
  end


  defp multiply_contact_for_recipients(_new_contact, []) do
    []
  end

  defp multiply_contact_for_recipients(new_contact, [{org, consent_map} | recipients]) do
    ch = new_contact
    |> Contact.add_encryption(org)
    |> Contact.add_consent(consent_map)

    [ch | multiply_contact_for_recipients(new_contact, recipients)]
  end

  @spec distribute_personal_data(Ecto.Changeset.t, Ecto.Changeset.t, ActionPage, map()) :: Ecto.Changeset.t
  def distribute_personal_data(new_supporter, new_contact, action_page, privacy) do
    with data_recipients <- Proca.Supporter.Privacy.recipients(action_page, privacy),
         contacts_for_recipients <- multiply_contact_for_recipients(new_contact, data_recipients) do
      new_supporter
      |> put_assoc(:contacts, contacts_for_recipients)
    end
  end

  def privacy_defaults(%{opt_in: _opt_in, lead_opt_in: _lead_opt_in} = p) do
    p
  end

  def privacy_defaults(%{opt_in: _opt_in} = p) do
    Map.put(p, :lead_opt_in, false)
  end

  @doc """
  """
  @spec create_supporter(ActionPage, %{contact: map(), privacy: map()}) :: Ecto.Changeset.t
  def create_supporter(action_page = %ActionPage{}, %{contact: contact, privacy: privacy}) do
    contact_schema = ActionPage.contact_schema(action_page)

    with data = %{valid?: true} = data <- apply(contact_schema, :from_input, [contact]),
         {new_contact = %{valid?: true}, fpr} <- apply(contact_schema, :to_contact, [data, action_page]),
           new_supporter = %{valid?: true} <- from_contact_data(data, action_page)
           |> distribute_personal_data(new_contact, action_page, privacy_defaults(privacy))
           |> put_change(:fingerprint, fpr)
    do
      new_supporter
    else
      invalid_data ->
        {:error, invalid_data}
    end
  end

  @doc "Returns %Supporter{} or nil"
  def find_by_fingerprint(fingerprint, org_id) do
    query =
      from(s in Supporter,
        join: ap in ActionPage,
        on: s.action_page_id == ap.id,
        where: ap.org_id == ^org_id and s.fingerprint == ^fingerprint,
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

  def transient_fields(supporter) do
    change(supporter, first_name: nil, email: nil)
  end
end
