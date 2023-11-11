using Godot;
using Npgsql;
using System;

namespace DotNetSix;

using BCrypt.Net;

public partial class PostgresDatabaseBackend : Node
{
	private NpgsqlDataSource dataSource;
	private string database = "";

	public bool Init()
	{
		var global = GetNode<Node>("/root/Global");
		string address = (string)global.Get("env_postgres_address");
		int port = (int)global.Get("env_postgres_port");
		string user = (string)global.Get("env_postgres_user");
		string password = (string)global.Get("env_postgress_password");
		database = (string)global.Get("env_postgress_db");

		string connectionString =
			$"Host={address};Port={port};Username={user};Password={password};Database={database};";
		try
		{
			dataSource = NpgsqlDataSource.Create(connectionString);
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			return false;
		}

		return true;
	}

	public Godot.Collections.Dictionary<string, Variant> CreateAccount(string username, string password)
	{
		var output = new Godot.Collections.Dictionary<string, Variant>();
		try
		{
			using var cmd = dataSource.CreateCommand(
				"INSERT INTO users (username, password) VALUES (@u, @p)"
			);
			cmd.Parameters.AddWithValue("u", username);
			cmd.Parameters.AddWithValue("p", BCrypt.HashPassword(password));
			cmd.ExecuteNonQuery();
		}
		catch (Exception ex)
		{
			GD.Print($"Error: {ex.Message}");
			output.Add("result", false);
			output.Add("error", "Oops something went wrong");
			return output;
		}

		output.Add("result", true);
		output.Add("error", "");
		return output;
	}

	public bool AuthenticateUser(string username, string password)
	{
		try
		{
			using var cmd = dataSource.CreateCommand(
				"SELECT password FROM users WHERE username = @username"
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
			using var cmd = dataSource.CreateCommand(
				"UPDATE users SET data = @d WHERE username = @u"
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
			using var cmd = dataSource.CreateCommand(
				"SELECT data FROM users WHERE username = @username"
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
}
