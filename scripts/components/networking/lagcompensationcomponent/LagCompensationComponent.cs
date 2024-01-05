using Godot;
using System;
using System.Collections.Generic;


public partial class LagCompensationComponent : Node2D
{
	[Export]
	public Area2D HitArea { get; set; }

	public const double PositionBufferTimeWindow = 1.0;

	// The node on which this component will work on
	private Node2D targetNode = null;

	private Node logger = null;

	private Node gameServer = null;

	private List<PositionElement> positionBuffer;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		// Fetch the logger singleton
		logger = GetNode<Node>("/root/GodotLogger");

		// Fetch the GameServer singleton
		gameServer = GetNode<Node>("/root/G");

		// Fetch the target node
		targetNode = GetNode<Node2D>("../");

		// This component should only run on the server-side
		if (!(bool)gameServer.Call("is_server"))
		{
			QueueFree();
		}

		// Register the component
		Godot.Collections.Dictionary componentList = targetNode.Get("component_list").AsGodotDictionary();
		if (componentList != null)
		{
			componentList = targetNode.Get("component_list").AsGodotDictionary();
			componentList.Add("lag_compensation", this);
		}

		// Init the list
		positionBuffer = new List<PositionElement> { };
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _PhysicsProcess(double delta)
	{
		// Get the current unix time
		double timestamp = Time.GetUnixTimeFromSystem();

		// Calculate the threshold timestamp for the time window
		double thresholdTimestamp = timestamp - PositionBufferTimeWindow;


		// Create a new element for this timestamp
		var myElement = new PositionElement
		{
			Timestamp = timestamp,
			Position = targetNode.Position
		};

		positionBuffer.Add(myElement);

		// Delete entries older than the time window
		while (positionBuffer.Count > 1 && positionBuffer[0].Timestamp < thresholdTimestamp)
		{
			positionBuffer.RemoveAt(0);
		}
	}
	// Check if a circle is colliding with the target node at a certain timestamp
	// The collision is check with the buffered position closest to the given timestamp
	public bool IsCircleCollidingWithTargetAtTimestamp(double timestamp, Vector2 circlePosition, float circleRadius)
	{
		var elementAtTimestamp = GetClosestTargetPositionToTimestamp(timestamp);

		if (elementAtTimestamp == null)
		{
			return false;
		}

		return elementAtTimestamp.Position.DistanceTo(circlePosition) < circleRadius;
	}

	private PositionElement GetClosestTargetPositionToTimestamp(double timestamp)
	{
		if (positionBuffer == null || positionBuffer.Count == 0)
		{
			return null;
		}

		PositionElement closestElement = positionBuffer[0];
		double minTimeDifference = Math.Abs(timestamp - closestElement.Timestamp);

		foreach (var element in positionBuffer)
		{
			double timeDifference = Math.Abs(timestamp - element.Timestamp);

			if (timeDifference < minTimeDifference)
			{
				closestElement = element;
				minTimeDifference = timeDifference;
			}
		}

		return closestElement;
	}
}


public class PositionElement
{
	public double Timestamp { get; init; }
	public Vector2 Position { get; init; }
}