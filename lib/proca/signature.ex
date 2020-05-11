defmodule Proca.Signature do
  use Ecto.Schema
  alias Proca.Repo
  alias Proca.{Org,Consent,Signature,Contact,ActionPage}
  import Ecto.Changeset
  import Ecto.Query

  schema "signatures" do
    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source
    
    many_to_many(
      :contacts,
      Proca.Contact,
      join_through: "contact_signatures",
      on_replace: :delete
    )

    field :fingerprint, :binary

    timestamps()
  end

  @doc false
  def changeset(signature, attrs) do
    signature
    |> cast(attrs, [])
    |> validate_required([])
  end

  def maybe_encrypt(contact, [pk]) do
    Contact.encrypt(contact, [pk])
  end

  def maybe_encrypt(contact, []) do
    [contact]
  end

  def changeset_recipients(contact, action_page, consents) do
    # could be 2 consents here for AP and Camp owners...
    with keys <- Org.get_public_keys(action_page.org) |> Org.active_public_keys(),
         [cch] <- maybe_encrypt(contact, keys), 
         cons <- Consent.from_opt_in(consents.opt_in),
         cch2 <- put_assoc(cch, :consent, cons)
      do
      changeset(%Signature{}, %{})
      |> put_assoc(:campaign, action_page.campaign)
      |> put_assoc(:action_page, action_page)
      |> put_assoc(:contacts, [cch2])
    end
  end

  def changeset_action_contact(action_page, %{contact: contact, privacy: cons}) do
    data_mod = ActionPage.data_module(action_page)

    case apply(data_mod, :from_input, [contact]) do
      %{valid?: true} = data ->
        with contact = %{valid?: true} <- apply(data_mod, :to_contact, [data, action_page]),
             sig = %{valid?: true} <- changeset_recipients(contact, action_page, cons),
             sig_fpr = %{valid?: true} <- apply(data_mod, :add_fingerprint, [sig, data])
          do
          sig_fpr
          else
            invalid_data ->
              {:error, invalid_data}
        end
      %{valid?: false} = invalid_data -> {:error, invalid_data}
    end
  end

  def find_by_fingerprint(fingerprint, campaign_id) do
    query = from(s in Signature,
      where: s.campaign_id == ^campaign_id and s.fingerprint == ^fingerprint,
      order_by: [desc: :inserted_at],
      limit: 1
    )
    Repo.one(query)
  end
end
