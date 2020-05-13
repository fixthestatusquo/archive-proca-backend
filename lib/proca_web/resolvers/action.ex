defmodule ProcaWeb.Resolvers.Action do
  # import Ecto.Query
  import Ecto.Changeset

  alias Proca.ActionPage
  alias Proca.Signature
  alias Proca.Contact
  alias Proca.Repo
  alias Proca.Source
  alias Proca.Consent
  alias ProcaWeb.Helper


  def get_action_page(%{action_page_id: id}) do
    case ActionPage.find(id) do
      nil -> {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page -> {:ok, action_page}
    end
  end

  defp add_tracking(sig, %{tracking: tr}) do
    with {:ok, src} <- Source.get_or_create_by(tr) do
      put_assoc(sig, :source, src) 
    else
      # XXX report this somehow? This is a strange situation where we could not insert Source.
      # even though we retried 2 times
      {:error, _m} -> sig
    end
  end

  defp add_tracking(sig, %{}) do
    sig
  end

  defp increment_counter(%{campaign_id: cid, action_page_id: apid}) do
    Proca.Server.Stats.increment(cid, apid)
  end

  defp output(%{contacts: contacts, fingerprint: fpr}) do
    con_ref = %{
      first_name: nil,
      fingerprint: Signature.base_encode(fpr)
    }

    with [con|_] <- contacts do
      %{con_ref | first_name: con.first_name}
    else
      _ -> con_ref
    end
  end


  def add_action_contact(_, signature, _) do # rename signature to action XXX
    with {:ok, action_page} <- get_action_page(signature),           # action page resolve

                                                                     # changeset of signature
    signature_changes = %{valid?: true} <- Signature.changeset_action_contact(action_page, signature)
    |> add_tracking(signature),

    {:ok, signature} <- Repo.insert(signature_changes)   # create signature

    # XXX changeset of action
    # XXX put_assoc signature action
    # XXX add tracking
      do

      # increment stats
      increment_counter(signature)

      # format return value 
      {:ok, output(signature)}

      else
        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, Helper.format_errors(changeset)}
        {:error, msg} -> {:error, msg}
      _ ->
               {:error, "other error?"}
    end
  end


  def get_signature(action_page, %{contact_ref: cref}) do
    case Signature.base_decode(cref) do
      {:ok, fpr} -> Signature.find_by_fingerprint(fpr, action_page.campaign_id)
      :error -> {:error, "contact_ref: Cannot decode from Base64url"}
    end
  end

  def add_action(_, action = %{contact_ref: _cref}, _) do
    with {:ok, action_page} <- get_action_page(action),           # action page resolve

    %Signature{} = signature <- get_signature(action_page, action)   # find signature

    # XXX changeset of action
    # XXX put_assoc signature action
    # XXX add tracking
      do

      # increment stats
      increment_counter(signature)

      IO.inspect(signature.contacts, label: "Contacts")
      # format return value 
      {:ok, output(signature)}

      else
        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, Helper.format_errors(changeset)}
        {:error, msg} -> {:error, msg}
        _ ->
          {:error, "other error?"}
    end
  end
end
