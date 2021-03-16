defmodule Proca.Confirm.AddPartner do 
  alias Proca.{Action, ActionPage, Confirm}
  import Proca.Changeset 
  import Proca.Repo

  @doc """
  # Inviting to a campaign (by email)
  
  add_partnern(action_page, nil, email) 
  - confirms this use     --- -----^   
  - times: 1
 
  # Inviting to a campaign (open)
  clone_action_page(action_page, nil)
  """
  def create(%ActionPage{id: id, campaign: _camp}, email) when is_bitstring(email) do
    %{
      operation: :add_parther,
      subject_id: id,
      email: email
    } |> Confirm.create()
  end
end

defimpl Proca.Confirm.Operation, for: :add_partner do 
  alias Proca.Confirm
  alias Proca.{ActionPage,Org, Staffer}
  import Proca.Repo
  import ProcaWeb.Helper, only: [has_error?: 3]

  defp try_create_copy(org, page, new_name, tryno \\ 0) do 
    name = if tryno > 0, do: new_name <> "-#{tryno}", else: new_name

    case ActionPage.create_copy_in(org, page, %{name: name}) do 
      {:ok, p} -> {:ok, p}
      {:error, ch = %{errors: errors}} -> 
        if has_error?(errors, :name, "has already been taken") do
          try_create_copy(org, page, new_name, tryno + 1)
        else 
          {:error, ch}
        end
    end
  end

  def run(%Confirm{operation: :add_partner, subject_id: ap_id}, :confirm, %Staffer{org: org}) do
    page = get(ActionPage, ap_id)
    if page do
      new_name = org.name <> "/" <> ActionPage.name_path(page.name)
      try_create_copy(org, page, new_name)
    else 
      {:error, "action page not found"}
    end
  end

  def run(_, _, _), do: :ok
end
