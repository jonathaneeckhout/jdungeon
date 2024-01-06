using Godot;
using System;
using System.Collections.Generic;


public partial class LagCompensationComponent : Node2D
{
	// The Collision shape used for collision
	[Export]
	private CollisionShape2D _hurtBox;

	// The window size of how long an element should stay in the positionBuffer
	public const double PositionBufferTimeWindow = 1.0;

	// The node on which this component will work on
	private Node2D targetNode = null;

	// The global logger used in the project
	private Node logger = null;

	// The gameserver to check if this is being ran on the server or client-side
	private Node gameServer = null;

	// The buffer containing all the positions inside the PositionBufferTimeWindow
	private List<PositionElement> positionBuffer;

	// The current supported collision shapes for lag compensation
	private enum HurtBoxShape { Circle, Capsule };

	// The shape of the hurtbox of the target node
	private HurtBoxShape hurtBoxShape = HurtBoxShape.Circle;


	// The radius of the hurtbox shape (used for circle and capsule shape)
	private float hurtBoxRadius = 0.0f;

	// The height of the hurtbox shape (used only for the capsule shape)
	private float hurtBoxHeight = 0.0f;

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
			return;
		}

		// Register the component
		Godot.Collections.Dictionary componentList = targetNode.Get("component_list").AsGodotDictionary();
		if (componentList != null)
		{
			componentList.Add("lag_compensation", this);
		}

		// Init the list
		positionBuffer = new List<PositionElement> { };

		// Get the radius if the shape is a circle
		if (_hurtBox.Shape is CircleShape2D)
		{
			hurtBoxShape = HurtBoxShape.Circle;
			hurtBoxRadius = (_hurtBox.Shape as CircleShape2D).Radius;
		}
		// Get the radius and the height if it's a capsule
		else if (_hurtBox.Shape is CapsuleShape2D)
		{
			hurtBoxShape = HurtBoxShape.Capsule;
			hurtBoxRadius = (_hurtBox.Shape as CapsuleShape2D).Radius;
			hurtBoxHeight = (_hurtBox.Shape as CapsuleShape2D).Height;
		}
		else
		{
			logger.Call("error", "The lag compensation hurtbox is using an unsupported shape");
		}
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
		// Get the element closest to the given timestamp
		PositionElement elementAtTimestamp = GetClosestTargetPositionToTimestamp(timestamp);

		// If it does not exist, the collision did not happen
		if (elementAtTimestamp == null)
		{
			return false;
		}

		bool colliding = false;

		// Calculate the actual position of the collisionshape as it can have an offset
		Vector2 collisionShapePostion = elementAtTimestamp.Position + _hurtBox.Position;

		// Check the collision according to the shape of the HurtBox
		switch (hurtBoxShape)
		{
			case HurtBoxShape.Circle:
				colliding = checkCircleCollision(collisionShapePostion, circlePosition, circleRadius);
				break;
			case HurtBoxShape.Capsule:
				colliding = checkCapsuleCollision(collisionShapePostion, circlePosition, circleRadius);
				break;
		}

		return colliding;

	}

	// Find the position in the poistionBuffer closest to the given timestamp
	private PositionElement GetClosestTargetPositionToTimestamp(double timestamp)
	{
		// If the buffer is invalid return null
		if (positionBuffer == null || positionBuffer.Count == 0)
		{
			return null;
		}


		// Init the closestElement with the first element of the buffer
		PositionElement closestElement = positionBuffer[0];

		// Calculate the time difference between the element and the given timestamp
		double minTimeDifference = Math.Abs(timestamp - closestElement.Timestamp);

		// Iterate over the position buffer
		foreach (var element in positionBuffer)
		{

			// Calculate the diff for each element
			double timeDifference = Math.Abs(timestamp - element.Timestamp);

			// Update the closest when the difference is smaller
			if (timeDifference < minTimeDifference)
			{
				closestElement = element;
				minTimeDifference = timeDifference;
			}
		}

		// Return the closest element
		return closestElement;
	}

	// Check the collision between 2 circles
	private bool checkCircleCollision(Vector2 targetNodePosition, Vector2 circlePosition, float circleRadius)
	{
		return targetNodePosition.DistanceTo(circlePosition) < circleRadius + hurtBoxRadius;
	}

	// Check the collision between a circle and a capsule
	// A limitation is that the capsule should not be rotated or only 90 degree or the simple Y check does not work
	private bool checkCapsuleCollision(Vector2 targetNodePosition, Vector2 circlePosition, float circleRadius)
	{

		float distanceToLine;
		// Calculate the distance between the circle's center and the capsule's central line according to the rotation
		if (_hurtBox.RotationDegrees == 0.0f)
		{
			distanceToLine = Math.Abs(targetNodePosition.Y - circlePosition.Y);
		}
		else if (Math.Abs(_hurtBox.RotationDegrees) - 90f < 0.1f)
		{
			distanceToLine = Math.Abs(targetNodePosition.X - circlePosition.X);
		}
		else
		{
			logger.Call("warn", "HurtBox has an invalid rotation");
			return false;
		}

		// Calculate the distance between the circle's center and the closest point on the capsule's central line
		float distanceToClosestPoint = distanceToLine - hurtBoxHeight / 2;

		// Check if the circle is within the range of the capsule's height
		if (distanceToClosestPoint > hurtBoxHeight / 2)
		{
			return false;
		}

		// Check if the circle is within the combined radius of the capsule and the circle
		float combinedRadius = hurtBoxRadius + circleRadius;
		return distanceToClosestPoint <= combinedRadius;
	}
}

// Simple class that contains information about the past positions and their timestamp
public class PositionElement
{
	public double Timestamp { get; init; }
	public Vector2 Position { get; init; }
}
