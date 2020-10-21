defmodule Proca.Contact.EciData do
  @moduledoc """
  Data format for ECI
  """
  use Ecto.Schema
  require Proca.Contact.EciDataRules

  Proca.Contact.EciDataRules.schema()

  @behaviour Input
  @impl Input
  def from_input(params) do


  end
end
