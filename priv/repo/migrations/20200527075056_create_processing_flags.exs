defmodule Proca.Repo.Migrations.CreateProcessingFlags do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :confirming, :boolean, null: false, default: false
      add :processing_status, :enum, null: false, default: false
      
    end
  end
end
