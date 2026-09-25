// Encounter / return transition controller.
// mode = "enter" for map -> battle, "exit" for battle -> map.

if (!variable_instance_exists(id, "mode")) mode = "enter";

timer = 0;

// Enter transition timing
flashFrames = 16;
barFrames = 44;
totalFrames = 82;

// Exit transition timing
exitCloseFrames = 32;
exitHoldFrames = 24;
exitOpenFrames = 48;
exitTotalFrames = exitCloseFrames + exitHoldFrames + exitOpenFrames;
exitCleanupDone = false;
