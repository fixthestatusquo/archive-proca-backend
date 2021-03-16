defprotocol Proca.Confirm.Operation do 
  alias Proca.Confirm
  alias Proca.Staffer
  alias Ecto.Changeset

  @spec run(Confirm, :confirm | :reject, Staffer | nil) :: :ok | {:error, bitstring() | Changeset}
  def run(confirm, verb, staffer)
end 
