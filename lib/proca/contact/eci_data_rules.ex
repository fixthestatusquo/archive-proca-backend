defmodule Proca.Contact.EciDataRules do
  @moduledoc """
  Rules generated from SQL released by EC (see utils/ECI).
  Provides `schema` macro to generate EciData embedded schema
  """
  @rules %{
    "at" => %{
      "id.card" => %{"pattern" => "[0-9]{7}|[0-9]{8}", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z][0-9]{7,8}", "skippable" => true}
    },
    "be" => %{
      "national.id.number" => %{
        "pattern" => "([0-9][0-9]).(0?0[1-9]|1[0-2]).([0-2]?[0-2][0-9]|3[0-1])-[0-9]{3}.[0-9]{2}",
        "skippable" => true
      }
    },
    "bg" => %{
      "personal.number" => %{"pattern" => "[0-9]{10}", "skippable" => true}
    },
    "common" => %{
      "city" => %{"empty" => false, "skippable" => false},
      "country" => %{"empty" => false, "skippable" => false},
      "date.of.birth" => %{"age" => true, "empty" => false, "skippable" => false},
      "family.names" => %{"empty" => false, "skippable" => false},
      "full.first.names" => %{"empty" => false, "skippable" => false},
      "postal.code" => %{"empty" => false, "skippable" => true},
      "street" => %{"empty" => false, "skippable" => false},
      "street.number" => %{"empty" => false, "skippable" => false}
    },
    "cy" => %{
      "id.card" => %{"pattern" => "[0-9]{1,10}", "skippable" => true},
      "passport" => %{
        "pattern_i" => "([bcej][0-9]{6})|(k[0-9]{8})|([ds]p[0-9]{7})",
        "skippable" => true
      }
    },
    "cz" => %{
      "id.card" => %{
        "pattern" => "([0-9]{9})|([0-9]{6}[a-z]{2}[0-9]{2})|([0-9]{6}[a-z]{2})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      },
      "passport" => %{"pattern" => "[0-9]{7,8}", "skippable" => true}
    },
    "de" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "dk" => %{"postal.code" => %{"pattern" => "[0-9]{4}", "skippable" => true}},
    "ee" => %{
      "personal.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "es" => %{
      "id.card" => %{"pattern_i" => "[0-9]{8}[a-z]", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true}
    },
    "fi" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "fr" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "gr" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "hr" => %{"personal.id" => %{"pattern" => "[0-9]{11}", "skippable" => true}},
    "hu" => %{
      "id.card" => %{
        "pattern_i" => "([0-9]{6}[a-z]{2})|([a-z]{2}[a-z][0-9]{6})|([a-z]{2}[a-z]{2}[0-9]{6})|([a-z]{2}[a-z]{3}[0-9]{6})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      },
      "passport" => %{
        "pattern_i" => "([a-z]{2}[0-9]{6})|([a-z]{2}[0-9]{7})",
        "skippable" => true
      },
      "personal.number" => %{
        "pattern" => "[0-9][0-9]{6}[0-9]{4}",
        "skippable" => true
      }
    },
    "ie" => %{"postal.code" => %{"skippable" => true}},
    "it" => %{
      "id.card" => %{
        "pattern_i" => "([a-z]{2}[0-9]{6,8})|([0-9]{7}[a-z]{2})|([a-z]{2}[0-9]{5}[a-z]{2})",
        "skippable" => true
      },
      "issuing.authority" => %{"empty" => false, "skippable" => true},
      "passport" => %{
        "pattern_i" => "([a-z]{2}[0-9]{7})|([a-z][0-9]{6})|([0-9]{6}[a-z])",
        "skippable" => true
      }
    },
    "lt" => %{
      "personal.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "lu" => %{"postal.code" => %{"pattern" => "[0-9]{4}", "skippable" => true}},
    "lv" => %{
      "personal.id" => %{"pattern" => "[0-9]{6}[0-9]{5}", "skippable" => true}
    },
    "mt" => %{"id.card" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true}},
    "nl" => %{
      "postal.code" => %{
        "pattern_i" => "[1-9][0-9]{3}[a-z]{2}",
        "skippable" => true
      }
    },
    "pl" => %{
      "national.id.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "pt" => %{
      "citizens.card" => %{
        "pattern_i" => "[0-9]{9}[a-z]{2}[0-9]",
        "skippable" => true
      },
      "id.card" => %{"pattern" => "[0-9]{1,8}", "skippable" => true},
      "passport" => %{
        "pattern_i" => "([a-z]{1}[0-9]{6})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      }
    },
    "ro" => %{
      "id.card" => %{"pattern_i" => "[a-z]{2}[0-9]{6}", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true},
      "personal.id" => %{"pattern" => "[0-9]{13}", "skippable" => true}
    },
    "se" => %{
      "personal.number" => %{
        "pattern" => "([0-9]{8}-[0-9]{4}|[0-9]{6}-[0-9]{4}|[0-9]{12}|[0-9]{10})",
        "skippable" => true
      }
    },
    "si" => %{
      "personal.number" => %{"pattern" => "[0-9]{13}", "skippable" => true}
    },
    "sk" => %{
      "postal.code" => %{"pattern" => "[089][0-9]{4}", "skippable" => true}
    }
  }


  # remove:
  # street_number
  # malta: residence_permit XXX
  @required_fields %{
    "at" => [:passport, :id_card, :full_first_names, :family_names],
    "be" => [:full_first_names, :family_names, :national_id_number],
    "bg" => [:personal_number, :full_first_names, :family_names],
    "cy" => [:full_first_names, :family_names, :passport, :id_card],
    "cz" => [:family_names, :passport, :id_card, :full_first_names],
    "de" => [:city, :country, :postal_code, :full_first_names, :street, :family_names, :date_of_birth],
    "dk" => [:country, :street, :postal_code, :date_of_birth, :full_first_names, :family_names, :city],
    "ee" => [:full_first_names, :family_names, :personal_number],
    "es" => [:id_card, :full_first_names, :family_names, :passport],
    "fi" => [:date_of_birth, :city, :country, :postal_code, :full_first_names, :street, :family_names],
    "fr" => [:city, :country, :postal_code, :full_first_names, :date_of_birth, :family_names, :street],
    "gr" => [:full_first_names, :family_names, :street, :city, :country, :postal_code],
    "hr" => [:full_first_names, :personal_id, :family_names, :passport],
    "hu" => [:id_card, :full_first_names, :family_names, :passport, :personal_number],
    "ie" => [:city, :country, :postal_code, :full_first_names, :street, :family_names, :date_of_birth],
    "it" => [:full_first_names, :family_names, :passport, :id_card],
    "lt" => [:full_first_names, :personal_number, :family_names],
    "lu" => [:postal_code, :full_first_names, :street, :family_names, :date_of_birth, :city, :country],
    "lv" => [:personal_id, :full_first_names, :family_names],
    "mt" => [:full_first_names, :family_names, :id_card],
    "nl" => [:full_first_names, :street, :family_names, :date_of_birth, :city, :country, :postal_code],
    "pl" => [:full_first_names, :family_names, :national_id_number],
    "pt" => [:family_names, :citizens_card, :passport, :id_card, :full_first_names],
    "ro" => [:personal_id, :passport, :id_card, :full_first_names, :family_names],
    "se" => [:full_first_names, :family_names, :personal_number],
    "si" => [:personal_number, :full_first_names, :family_names],
    "sk" => [:street, :postal_code, :city, :country, :full_first_names, :family_names, :date_of_birth]
  }

  @alternative_fields [
    :passport,
    :id_card,
    :residence_permit,
    :personal_number,
    :personal_id,
    :national_id_number,
    :citizens_card
  ]

  require Ecto.Schema

  def rules() do
    @rules
  end

  def required(country) do
    Map.get(@required, country)
  end

  def fields(rls) do
    Map.values(rls)
    |> Enum.map(&(Map.keys(&1)))  # get field names from each rule
    |> List.flatten               # flatten into a list, sort, uniq
    |> Enum.sort
    |> Enum.uniq
    |> Enum.map(&String.replace(&1, ".", "_"))  # turn . -> _
    |> Enum.map(&String.to_atom(&1))            # make atoms
  end

  defmacro schema do
    fs = fields(rules)
    types = %{date_of_birth: :date}
    quote do
      Ecto.Schema.embedded_schema do
        unquote(Enum.map(fs, fn f -> quote do
                Ecto.Schema.field unquote(f), unquote(Map.get(types, f, :string))
              end
            end))
      end
    end
  end
end
