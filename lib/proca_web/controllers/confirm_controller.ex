defmodule ProcaWeb.ConfirmController do 
  use ProcaWeb, :controller
  import Ecto.Changeset
  import Ecto.Query
  import Proca.Repo
  alias Proca.{Supporter,Action}
  alias Proca.Server.Processing


  def confirm(conn, params) do
    with {:ok, args} <- parse_params(params),
         {:ok, action} <- find_action(args),
         :ok <- perform_confirm(action, args.verb)
    do
      conn
      |> redirect(to: Map.get(args, :redir, "/"))
      |> halt()
    else 
      {:error, stat, msg} -> 
        conn |> resp(stat, error_msg(msg)) |> halt()
    end
  end

  def parse_params(params) do 
    types = %{
      action_id: :integer,
      verb: :string,
      ref: :string,
      redir: :string
    }

    args = cast({%{}, types}, params, Map.keys(types))
    |> validate_inclusion(:verb, ["supacc", "suprej", "actacc", "actrej"])
    |> Supporter.decode_ref(:ref)
    |> validate_required([:action_id, :verb, :ref])

    if args.valid? do 
      {:ok, apply_changes(args)}
    else 
      {:error, 400, "malformed link"}
    end
  end


  def find_action(%{action_id: action_id, ref: ref}) do 
    action = from(a in Action, 
      join: s in Supporter, on: s.id == a.supporter_id,
      where: a.id == ^action_id and s.fingerprint == ^ref, 
      preload: [supporter: s])
    |> one()

    if is_nil(action) do 
      {:error, 404, "malformed link"}
    else 
      {:ok, action}
    end
  end

  def perform_confirm(action = %Action{supporter: sup}, "supacc") do 
    case sup.processing_status do 
      :new -> {:error, 400, "operation not allowed"}
      :confirming -> 
        Processing.process_async(
          %{action | supporter: update!(change(sup, processing_status: :accepted))}
        )
      :rejected -> {:error, 400, "supporter data already rejected"}
      :accepted -> :ok
      :delivered -> :ok
    end
  end

  def perform_confirm(action = %Action{supporter: sup}, "suprej") do 
    case sup.processing_status do 
      :new -> {:error, 400, "operation not allowed"}
      :confirming -> 
        update!(change(sup, processing_status: :rejected))
        :ok
      :rejected -> :ok
      :accepted -> {:error, 400, "supporter data already processed"}
      :delivered -> {:error, 400, "supporter data already processed"}
    end
  end

  def perform_confirm(action = %Action{}, "actacc") do 
    case action.processing_status do 
      :new -> {:error, 400, "operation not allowed"}
      :confirming -> 
        Processing.process_async(
          update!(change(action, processing_status: :accepted))
        )
      :rejected -> {:error, 400, "action data already rejected"}
      :accepted -> :ok
      :delivered -> :ok
    end
  end

  def perform_confirm(action = %Action{supporter: sup}, "actrej") do 
    case sup.processing_status do 
      :new -> {:error, 400, "operation not allowed"}
      :confirming -> 
        update!(change(action, processing_status: :rejected))
        :ok
      :rejected -> :ok
      :accepted -> {:error, 400, "action data already processed"}
      :delivered -> {:error, 400, "action data already processed"}
    end
  end

  defp error_msg(msg), do: %{errors: [%{message: msg}]} |> Jason.encode!
end 
