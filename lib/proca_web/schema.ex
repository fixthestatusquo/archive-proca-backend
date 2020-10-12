defmodule ProcaWeb.Schema do
  use Absinthe.Schema
  alias ProcaWeb.Resolvers

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.CampaignTypes)
  import_types(ProcaWeb.Schema.ActionTypes)
  import_types(ProcaWeb.Schema.OrgTypes)
  #import_types(ProcaWeb.Schema.Subscriptions)

  query do
    import_fields :campaign_queries
    import_fields :action_queries
    import_fields :org_queries
  end

  mutation do
    import_fields :campaign_mutations
    import_fields :action_mutations
    import_fields :org_mutations
  end

  subscription do
    field :action_page_updated, :action_page do
      arg :org_name, non_null(:string)

      config fn args, o ->
        IO.inspect(args, label: "config (args,")
        IO.inspect(Map.get(o, :context), label: "config (, o)")

        {:ok, topic: args.org_name}
      end

      resolve fn action_page, a, _->
        IO.inspect(action_page, label: "sub resolve 0")
        IO.inspect(a, label: "sub resolve a")

        {:ok, action_page}
      end
    end
  end
end
