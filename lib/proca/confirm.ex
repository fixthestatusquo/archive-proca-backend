defmodule Proca.Confirm do
  @moduledoc """
  OPERATION
  SUBJECT_ID
  OBJECT_ID
  CODE
  # Asking to join a campaign:
  
          subject v   object v
  join_campaign(org, campaign)
  - confirms someone from ^ this org.
    Staffers with proper permission? 
  - times: 1
  XXX should send email after
  
  Confirm supporter data
  confirm_supporter(action, supporter)  # or maybe supported can be confirmed by a ref ?
 
  Confirm action data
  confirm_supporter(action, action_page)  # XXX currently no idea how this would work within system; the custom queue will use authenticated API (no confirm code)
 
  CONFIRMS/REJECTS ARE SYNC
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import Proca.Repo
  alias Proca.Confirm
  alias Proca.{ActionPage,Campaign,Org}

  schema "confirms" do
    field :operation, ConfirmOperation
    field :subject_id, :integer
    field :object_id, :integer
    field :email, :string
    field :code, :string
    field :charges, :integer, default: 1

    timestamps()
  end


  @doc false
  def changeset(confirm, attrs) do
    confirm
    |> cast(attrs, [:operation, :subject_id, :object_id, :email, :charges])
    |> add_code()
    |> validate_required([:operation, :subject_id, :charges, :code])
  end

  def changeset(attrs), do: changeset(%Confirm{}, attrs)

  def add_code(ch) do 
    code = Proca.Confirm.SimpleCode.generate()
    change(ch, code: code)
  end

  def by_open_code(code) when is_bitstring(code) do
    from(c in Confirm, where: c.code == ^code and is_nil(c.object_id), limit: 1)
    |> one()
  end

  def by_object_code(object_id, code) when is_integer(object_id) and is_bitstring(code) do 
    from(c in Confirm, where: c.code == ^code and is_nil(c.object_id), limit: 1)
    |> one()
  end

  def by_email_code(email, code)  when is_bitstring(email) and is_bitstring(code) do 
    from(c in Confirm, where: c.code == ^code and c.email == ^email, limit: 1)
    |> one()
  end

  def reject(confirm = %Confirm{}) do
    confirm |> change(charges: 0) |> update!
    :ok
  end

  def confirm(confirm = %Confirm{}) do 
    if confirm.charges <= 0 do 
      {:error, :expired}
    else
      confirm |> change(charges: confirm.charges - 1) |> update!
      run(confirm)
    end
  end

  @doc """
  # Inviting to a campaign (by email)
  
  add_partnern(action_page, nil, email) 
  - confirms this use     --- -----^   
  - times: 1
 
  # Inviting to a campaign (open)
  clone_action_page(action_page, nil)
  """
  def create(:add_parther, %ActionPage{id: id, campaign: camp}, email) do
    cnf = %{
      operation: :add_parther,
      subject_id: id,
      email: email
    } |> changeset() |> insert!
    
    cnf
  end

  def run(_) do 
    :ok
  end

  def notify_by_email(email, cnf) do 
    instance = Org.get_by_name(Org.instance_org_name, [:email_backend, :template_backend])

  
  end

end
