defmodule Mix.Tasks.PowAssent.Ecto.Gen.MigrationTest do
  use PowAssent.Test.Mix.TestCase

  alias Mix.Tasks.PowAssent.Ecto.Gen.Migration

  defmodule Repo do
    def __adapter__, do: true
    def config, do: [priv: "tmp/#{inspect(Migration)}", otp_app: :pow_assent]
  end

  @tmp_path        Path.join(["tmp", inspect(Migration)])
  @migrations_path Path.join([@tmp_path, "migrations"])
  @options         ["-r", inspect(Repo)]

  setup do
    File.rm_rf!(@tmp_path)
    File.mkdir_p!(@tmp_path)

    :ok
  end

  test "generates migration" do
    File.cd!(@tmp_path, fn ->
      Migration.run(@options)

      assert [migration_file] = File.ls!(@migrations_path)
      assert String.match?(migration_file, ~r/^\d{14}_create_user_identities\.exs$/)

      file = @migrations_path |> Path.join(migration_file) |> File.read!()

      assert file =~ "defmodule #{inspect(Repo)}.Migrations.CreateUserIdentities do"
      assert file =~ "create table(:user_identities)"
      assert file =~ "add :provider, :string, null: false"
      assert file =~ "add :uid, :string, null: false"
      assert file =~ "add :user_id, references(\"users\", on_delete: :nothing)"
      assert file =~ "timestamps()"
    end)
  end

  test "doesn't make duplicate migrations" do
    File.cd!(@tmp_path, fn ->
      Migration.run(@options)

      assert_raise Mix.Error, "migration can't be created, there is already a migration file with name CreateUserIdentities.", fn ->
        Migration.run(@options)
      end
    end)
  end

  test "generates with binary_id" do
    options = @options ++ ~w(--binary-id)

    File.cd!(@tmp_path, fn ->
      Migration.run(options)

      assert [migration_file] = File.ls!(@migrations_path)
      assert String.match?(migration_file, ~r/^\d{14}_create_user_identities\.exs$/)

      file = @migrations_path |> Path.join(migration_file) |> File.read!()

      assert file =~ "create table(:user_identities, primary_key: false)"
      assert file =~ "add :id, :binary_id, primary_key: true"
      assert file =~ "add :user_id, references(\"users\", on_delete: :nothing, type: :binary_id)"
    end)
  end
end
