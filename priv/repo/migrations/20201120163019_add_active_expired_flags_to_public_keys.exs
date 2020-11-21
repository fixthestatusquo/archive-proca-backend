defmodule Proca.Repo.Migrations.AddActiveExpiredFlagsToPublicKeys do
  use Ecto.Migration

  def change do
    alter table(:public_keys) do
      add :active, :boolean, null: false, default: false
      add :expired, :boolean, null: false, default: false
    end

    execute "UPDATE public_keys SET expired = TRUE WHERE expired_at IS NOT NULL"
    execute "UPDATE public_keys SET active = TRUE WHERE expired_at IS NULL"

    alter table(:public_keys) do
      remove :expired_at
    end
  end
end
