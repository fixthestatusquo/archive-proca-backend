defmodule ProcaWeb.Schema.EciSchema do
  use Absinthe.Schema

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.CampaignTypes)
  import_types(ProcaWeb.Schema.ActionTypes)
  import_types(ProcaWeb.Schema.OrgTypes)
  import_types(ProcaWeb.Schema.SubscriptionTypes)

  # use Absinthe.Schema.Notation

  query do
    @desc "Get action page"
    field :action_page, :public_action_page do
      @desc "Get action page by id."
      arg(:id, :integer)
      @desc "Get action page by name the widget is displayed on"
      arg(:name, :string)
      @desc "Get action page by url the widget is displayed on (DEPRECATED, use name)"
      arg(:url, :string)

      resolve(&Resolvers.ActionPage.find/3)
    end
  end

  mutation do
    @desc "Adds an action with contact data"
    field :add_action_contact, type: :contact_reference do
      arg(:action_page_id, non_null(:integer))
      @desc "Action data"
      arg(:action, non_null(:action_input))

      @desc "GDPR communication opt"
      arg(:contact, non_null(:eci_contact_input))
      @desc "Signature action data"
      arg(:privacy, non_null(:consent_input))

      @desc "Tracking codes (UTM_*)"
      arg(:tracking, :tracking_input)

      # XXX is this handled?
      @desc "Links to previous contact reference"
      arg(:contact_ref, :id)

      resolve &Resolvers.Action.add_action_contact/3
    end
  end

  input_object :eci_contact_input do
    @desc "Country"
    field :country, :string

    @desc "City"
    field :city, :string

    @desc "Postal code"
    field :postal_code, :string

    @desc "Street with number and appartment"
    field :street, :string

    @desc "First names"
    field :full_first_names, :string
    @desc "Last names"
    field :family_names, :string
    @desc "Date of birth in ISO 8601 format YYYY-MM-DD"
    field :date_of_birth, :date

    @desc "Citizens Card"
    field :citizens_card, :string

    @desc "Id card"
    field :id_card, :string

    @desc "National id number"
    field :national_id_number, :string

    @desc "Passport"
    field :passport, :string

    @desc "Personal ID"
    field :personal_id, :string

    @desc "Personal Number"
    field :personal_number, :string
    # residence_permit # also alternative

    # issuing_authority

  end
end
