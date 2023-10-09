using Godot;
using Npgsql;
using System;

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

		string connectionString =
			$"Host={address};Port={port};Username={user};Password={password};Database={database};";
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
			using var cmd = new NpgsqlCommand(
				"INSERT INTO users (username, password) VALUES (@u, @p)",
				conn
			);
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
			using var cmd = new NpgsqlCommand(
				"SELECT password FROM users WHERE username = @username",
				conn
			);
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

	public bool StorePlayerData(string username, Godot.Collections.Dictionary<string, Variant> data)
	{
		try
		{
			using var cmd = new NpgsqlCommand(
				"UPDATE users SET data = @d WHERE username = @u",
				conn
			);
			cmd.Parameters.AddWithValue("u", username);
			cmd.Parameters.Add(new NpgsqlParameter("@d", NpgsqlTypes.NpgsqlDbType.Json) { Value = data.ToString() });
			cmd.ExecuteNonQuery();
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			return false;
		}
		return true;
	}

	public Godot.Collections.Dictionary<string, Variant> LoadPlayerData(string username)
	{
		var output = new Godot.Collections.Dictionary<string, Variant>();
		try
		{
			using var cmd = new NpgsqlCommand(
				"SELECT data FROM users WHERE username = @username",
				conn
			);
			cmd.Parameters.AddWithValue("username", username);

			using NpgsqlDataReader reader = cmd.ExecuteReader();

			if (reader.Read())
			{
				string stringData = reader["data"].ToString();
				var jsonFile = Json.ParseString(stringData);
				output = (Godot.Collections.Dictionary<string, Variant>)jsonFile;
				return output;
			}
			else
			{
				return output;
			}
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			return output;
		}
	}

	static bool IsUsernameValid(string username)
	{
		return true;
	}

	static bool IsPasswordValid(string password)
	{
		return true;
	}
}
