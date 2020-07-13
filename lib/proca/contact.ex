defmodule Proca.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Contact

  schema "contacts" do
    belongs_to :supporter, Proca.Supporter

    # Personally Identifiable Information
    field :payload, :binary
    field :crypto_nonce, :binary
    belongs_to :public_key, Proca.PublicKey
    belongs_to :sign_key, Proca.PublicKey

    # Consent
    field :communication_consent, :boolean, default: false
    field :communication_scopes, {:array, :string}, default: []
    field :delivery_consent, :boolean, default: false

    timestamps()
  end

  @spec build(map()) :: Ecto.Changeset.t(Contact)
  def build(attrs) when is_map(attrs) do
    external_attrs = attrs |> ProperCase.to_camel_case()
    case Jason.encode(external_attrs) do
      {:ok, payload} -> change(%Contact{}, %{payload: payload})
    end
  end

  def add_consent(contact_ch, attrs) do
    contact_ch
    |> cast(attrs, [:communication_consent, :communication_scopes, :delivery_consent])
    |> validate_required([:communication_consent, :communication_scopes, :delivery_consent])
  end

  @spec add_encryption(Ecto.Changeset.t(), Proca.Org | Proca.PublicKey | nil) :: Ecto.Changeset.t()
  def add_encryption(contact_ch, public_key) when is_nil(public_key) do
    contact_ch
  end

  def add_encryption(contact_ch, org = %Proca.Org{}) do
    add_encryption(contact_ch, Proca.Org.active_public_key(org))
  end

  def add_encryption(contact_ch, public_key = %Proca.PublicKey{}) do
    case contact_ch do
      %{changes: %{payload: payload}} ->
        case Proca.Server.Encrypt.encrypt(public_key, payload) do
          {penc, nonce, sign_id} when is_binary(penc) ->
            contact_ch
            |> put_change(:payload, penc)
            |> put_change(:crypto_nonce, nonce)
            |> put_assoc(:public_key, public_key)
            |> put_change(:sign_key_id, sign_id)

          {:error, msg} ->
            add_error(contact_ch, :payload, msg)
        end

      no_payload ->
        add_error(no_payload, :payload, "Contact payload required to encrypt")
    end
  end

  @doc "Encrypt this contact changeset for a list of keys.
  Returns lists of Contact records with payload encrypted for each key."
  def encrypt(_contact_ch, []) do
    []
  end

  @spec encrypt(Ecto.Changeset.t(), [Proca.PublicKey]) :: [Ecto.Changeset.t()]
  def encrypt(contact_ch, [pk | public_keys]) do
    enc_ch = add_encryption(contact_ch, pk)
    [enc_ch | encrypt(contact_ch, public_keys)]
  end

  def base_encode(data) when is_bitstring(data) do
    Base.url_encode64(data, padding: false)
  end

  def base_decode(encoded) when is_bitstring(encoded) do
    Base.url_decode64(encoded, padding: false)
  end
end
