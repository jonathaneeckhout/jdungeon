using Godot;
using Npgsql;
using System;
using System.Threading.Tasks;

namespace DotNetSix;

using BCrypt.Net;


public partial class JPostgresDatabaseBackend : Node
{
	private NpgsqlConnection conn;
	private string database = "";

	public bool Init()
	{
		var j = GetNode<Node>("/root/J");
		var global = (Node)j.Get("global");

		string address = (string)global.Get("env_postgres_address");
		int port = (int)global.Get("env_postgres_port");
		string user = (string)global.Get("env_postgres_user");
		string password = (string)global.Get("env_postgress_password");
		database = (string)global.Get("env_postgress_db");

		string connectionString = $"Host={address};Port={port};Username={user};Password={password};Database={database};";
		try
		{
			conn = new NpgsqlConnection(connectionString);
			conn.Open();
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			return false;
		}

		return true;
	}

	public bool CreateAccount(string username, string password)
	{
		if (!IsUsernameValid(username))
		{
			GD.Print("Invalid username");
			return false;
		}

		if (!IsPasswordValid(password))
		{
			GD.Print("Invalid password");
			return true;
		}
		try
		{
			using var cmd = new NpgsqlCommand("INSERT INTO users (username, password) VALUES (@u, @p)", conn);
			cmd.Parameters.AddWithValue("u", username);
			cmd.Parameters.AddWithValue("p", BCrypt.HashPassword(password));
			cmd.ExecuteNonQuery();
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			return false;
		}
		return true;
	}

	public bool AuthenticateUser(string username, string password)
	{
		try
		{
			using var cmd = new NpgsqlCommand("SELECT password FROM users WHERE username = @username", conn);
			cmd.Parameters.AddWithValue("username", username);

			using NpgsqlDataReader reader = cmd.ExecuteReader();

			if (reader.Read())
			{
				string storedPasswordHash = reader["password"].ToString();

				bool passwordMatches = BCrypt.Verify(password, storedPasswordHash);
				return passwordMatches;
			}
			else
			{
				return false;
			}
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			return false;
		}


	}

	static bool IsUsernameValid(string username)
	{
		return true;
		return !string.IsNullOrWhiteSpace(username) && username.Length >= 5;
	}

	static bool IsPasswordValid(string password)
	{
		return true;
		return !string.IsNullOrWhiteSpace(password) && password.Length >= 8;
	}
}
