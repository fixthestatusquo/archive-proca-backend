defmodule ContactTest do
  use Proca.DataCase
  doctest Proca.Contact
  alias Proca.{Contact, PublicKey, Org, Repo, ActionPage, Supporter}
  alias Proca.Server.Encrypt
  
  test "build contact and supporter from basic data" do
    action_page = Factory.build(:action_page)

    # check converting attrs into data struct
    attrs = Factory.build(:basic_data_pl)
    new_data = ActionPage.new_data(attrs, action_page)
    assert new_data.valid?
    data = apply_changes new_data
    assert %Proca.Contact.BasicData{} = data

    # check creating contact from this
    {contact_ch = %Ecto.Changeset{}, fpr} = ActionPage.new_contact(data, action_page)
    contact = apply_changes contact_ch
    assert %Contact{} = contact
    assert not is_nil contact.payload

    # Check payload
    decoded_data = Jason.decode! contact.payload
    assert decoded_data["firstName"] == attrs.first_name
    assert decoded_data["lastName"] == attrs.last_name
    assert is_nil contact.crypto_nonce
    assert not contact.communication_consent
    assert not contact.delivery_consent
    assert contact.communication_scopes == []

    # check supporter
    new_supporter = ActionPage.new_supporter(data, action_page)
    assert new_supporter.valid?

    supporter = apply_changes new_supporter
    assert %Supporter{} = supporter
    assert supporter.first_name == attrs.first_name
    assert supporter.email == attrs.email
    assert not is_nil supporter.campaign
    assert not is_nil supporter.action_page
  end

  test "basic data without email fails" do
    action_page = Factory.build(:action_page)

    attrs = %{Factory.build(:basic_data_pl) | email: ""}
    data = ActionPage.new_data(attrs, action_page)
    assert not data.valid?
    assert not is_nil List.keyfind(data.errors, :email, 0)
  end

  test "basic data creates contact changeset" do
    alias Proca.Contact.BasicData
    ap = Factory.insert(:action_page)
    chg = BasicData.from_input(%{
          name: "Hans Castorp",
          email: "hans@castorp.net"
                               })
    assert chg.valid?
    data = apply_changes(chg)

    con_chg = Proca.Contact.BasicData.to_contact(data, ap)
    {%{valid?: true, changes: cd}, fpr} = con_chg

    assert byte_size(fpr) > 0
  end
end
