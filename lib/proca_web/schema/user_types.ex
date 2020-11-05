defmodule ProcaWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.Authorized

  object :user_queries do

    field :user, :user do
      middleware Authorized
    end
  end

  object :user do
    field :email, non_null(:string)
    field :roles, list_of(non_null(:user_role))
  end

  object :user_role do
    field :org, non_null(:org)
    field :role, :string
  end
end
