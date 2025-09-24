# Blueprint-Style Node Connection System

This system allows you to connect image operation blocks using bezier curves, similar to Unreal Engine's Blueprint system.

## How to Use

1. **Right-click on a pin** to start creating a connection
2. **Right-click on another compatible pin** to complete the connection
3. **Left-click anywhere or right-click in empty space** to cancel a connection

## Connection Rules

- **Output pins** (right side) can connect to **Input pins** (left side)
- **Input pins** can only have **one connection** at a time
- **Output pins** can have **multiple connections**
- Pins on the **same block cannot be connected** to each other
- **Connections are shown as white bezier curves**
- **Active connection being drawn is shown in yellow**

## System Architecture

### Components

1. **Pin.gd** - Handles individual pin behavior and input detection
2. **ConnectionManager.gd** - Manages all connections and drawing
3. **image_operation_bloc.gd** - Updated to work with the pin system

### Pin Types

Each pin has a `pin_type` property that can be:

- `Pin.PinType.INPUT` - For input pins (left side of blocks)
- `Pin.PinType.OUTPUT` - For output pins (right side of blocks)

### Block Configurations

Blocks support different pin configurations:

- `ONEBYONE` - 1 input, 1 output
- `ONEBYTHREE` - 1 input, 3 outputs
- `THREEBYONE` - 3 inputs, 1 output
- `TWOBYONE` - 2 inputs, 1 output

## Technical Details

- Connections are drawn using cubic bezier curves
- The ConnectionManager is added to the main scene and handles all drawing
- Pins automatically find their parent block and connection manager
- When blocks are deleted, their connections are automatically cleaned up
- The system uses Godot's built-in input handling and drawing functions

## Setup Instructions

### 1. Prerequisites

Make sure you have these files in your project:

- `Scripts/Pin.gd` - Pin behavior script
- `Scripts/connectionManager.gd` - Connection manager script
- `Scripts/image_operation_bloc.gd` - Updated block script
- `prefab/image_operation_bloc.tscn` - Block prefab with pin scripts attached

### 2. Scene Setup

The main scene (`mainScene2D.tscn`) should have:

- A `ConnectionManager` node as a child of `CanvasLayer`
- The ConnectionManager should be full-screen with `mouse_filter = 2` (ignore mouse)
- Image operation blocks in the scene hierarchy

### 3. Pin Configuration

Each pin in the `image_operation_bloc.tscn` prefab should:

- Have the `Pin.gd` script attached
- Be a `TextureRect` node
- Have proper positioning (left side for inputs, right side for outputs)

### 4. Block Configuration

Each image operation block should:

- Have the updated `image_operation_bloc.gd` script
- Have `@onready` references to all pins
- Call `_setup_pins()` in `_ready()`

### 5. Testing the System

1. Run the main scene
2. Look for debug output in the console:
   - "ConnectionManager ready - position: (0, 0) size: (screen_size)"
   - Pin setup messages when blocks are created
3. Right-click on pins to test connections
4. Check console for connection debug messages

## Debugging

- Enable debug prints in the scripts to see connection events
- Check the console for warnings about missing ConnectionManager
- Verify that pins have proper parent_block references
- Make sure ConnectionManager is properly positioned and sized
- Verify script paths are correct in scene files

## Common Issues

### "ConnectionManager not found"

- Ensure ConnectionManager node exists in the main scene
- Check that the node name is exactly "ConnectionManager"
- Verify the script path is correct

### "Function to_local() not found"

- This should be fixed with manual coordinate conversion
- Check that ConnectionManager extends Control

### Pins not responding to clicks

- Verify Pin.gd script is attached to pin nodes
- Check that pins have proper parent_block references
- Ensure \_gui_input() is being called

### Connections not drawing

- Check that ConnectionManager's \_draw() function is being called
- Verify global_position calculations are correct
- Make sure queue_redraw() is being called when needed

### ConnectionManager has wrong position/size

**Symptoms**: Console shows position like (0, 349) instead of (0, 0), or size smaller than screen
**Solutions**:

- Ensure ConnectionManager is a **direct child of CanvasLayer** (not nested deeper)
- Set **anchors_preset = 15** (full rect)
- Set **anchor_right = 1.0** and **anchor_bottom = 1.0**
- Use **Control** node type, not ColorRect
- Set **mouse_filter = 2** (ignore mouse input)
