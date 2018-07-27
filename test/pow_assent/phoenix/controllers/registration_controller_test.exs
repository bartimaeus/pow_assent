defmodule PowAssent.Phoenix.RegistrationControllerTest do
  use PowAssent.Test.Phoenix.ConnCase

  @provider "test_provider"

  setup %{conn: conn} do
    conn = Plug.Conn.put_session(conn, :pow_assent_params, %{"uid" => "1", "name" => "John Doe"})

    {:ok, conn: conn}
  end

  describe "GET /auth/:provider/add-user-id" do
    test "shows", %{conn: conn} do
      conn = get conn, Routes.pow_assent_registration_path(conn, :add_user_id, @provider)
      assert html_response(conn, 200)
    end

    test "with missing session", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.delete_session(:pow_assent_params)
        |> get(Routes.pow_assent_registration_path(conn, :add_user_id, @provider))

      assert redirected_to(conn) == "/logged-out"
      assert get_flash(conn, :error) == "Invalid Request."
    end
  end

  describe "POST /auth/:provider/create" do
    test "with missing session", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.delete_session(:pow_assent_params)
        |> post(Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{email: "foo@example.com"}})

      assert redirected_to(conn) == "/logged-out"
      assert get_flash(conn, :error) == "Invalid Request."
    end

    test "with valid params", %{conn: conn} do
      conn = post conn, Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{email: "foo@example.com"}}

      assert redirected_to(conn) == "/registration_created"
      assert user = Pow.Plug.current_user(conn)
      assert user.email == "foo@example.com"
      assert get_flash(conn, :info) == "Welcome! Your account has been created."
    end

    test "with already taken user id field", %{conn: conn} do
      conn = post conn, Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{email: "taken@example.com"}}

      assert html_response(conn, 200) =~ "has already been taken"
    end

    test " with invalid user id field (email)", %{conn: conn} do
      conn = post conn, Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{email: "foo"}}

      assert html_response(conn, 200) =~ "has invalid format"
    end

    test "with duplicate identity", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_session(:pow_assent_params, %{"uid" => "duplicate", "name" => "John Doe"})
        |> post(Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{email: "foo@example.com"}})

      assert redirected_to(conn) == "/logged-out"
      assert get_flash(conn, :error) == "Invalid Request."
    end
  end

  describe "GET /auth/:provider/create with PowEmailConfirmation" do
    setup %{conn: conn} do
      Application.put_env(:pow_assent_test, :config,
        user: PowAssent.Test.Ecto.Users.EmailConfirmUser,
        mailer_backend: PowAssent.Test.Phoenix.MailerMock)

      on_exit(fn -> Application.put_env(:pow_assent_test, :config, []) end)

      {:ok, conn: conn}
    end

    test "with valid", %{conn: conn} do
      conn = post conn, Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{email: "foo@example.com"}}

      assert redirected_to(conn) == "/registration_created"
      assert get_flash(conn, :info) == "Welcome! Your account has been created."

      assert user = Pow.Plug.current_user(conn)
      assert user.email == "foo@example.com"

      assert_received {:mail_mock, mail}
      mail.html =~ "http://example.com/confirm-email/"
    end

    test "with email from provider", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_session(:pow_assent_params, %{"uid" => "1", "name" => "John Doe", "email" => "foo@example.com"})
        |> post(Routes.pow_assent_registration_path(conn, :create, @provider), %{user: %{}})

      assert redirected_to(conn) == "/registration_created"

      refute_received {:mail_mock, _mail}
    end
  end
end
