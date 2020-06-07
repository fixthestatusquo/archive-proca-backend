defmodule Proca.Stage.Support do
  alias Proca.{Action}
  alias Proca.Repo
  import Ecto.Query, only: [from: 2]


  def present_actions(action_ids) do
    from(a in Action,
      where: a.id in ^action_ids,
      preload: [
        [supporter: [[contacts: :public_key], :consent]],
        :source,
        :fields
      ])
      |> Repo.all()
      |> Enum.map(fn a -> Proca.Server.Processing.external_representation(a) end)
  end
end
