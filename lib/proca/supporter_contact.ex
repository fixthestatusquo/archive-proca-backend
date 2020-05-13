defmodule Proca.SupporterContact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "supporter_contacts" do
    field :contact_id, :id
    field :supporter_id, :id
  end

  @doc false
  def changeset(contact_signature, attrs) do
    contact_signature
    |> cast(attrs, [])
    |> validate_required([])
  end
end
