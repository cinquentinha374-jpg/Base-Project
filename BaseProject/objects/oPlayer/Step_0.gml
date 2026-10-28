// Freeze the field character only during the battle transition.
if (variable_global_exists("inBattleTransition") && global.inBattleTransition)
{
    image_speed = 0;
    exit;
}

// Opening the field inventory must be handled before movement and must not
// depend on a menu already existing. The menu itself pauses movement on later steps.
if (!instance_exists(oMenu) && keyboard_check_pressed(ord("I")))
{
    if (!variable_global_exists("inventory") || !is_array(global.inventory)) global.inventory = [];
    if (!variable_global_exists("party") || !is_array(global.party)) global.party = [];
    var _options = InventoryGetMenuOptions(id);
    Menu(camera_get_view_x(view_camera[0]) + 24, camera_get_view_y(view_camera[0]) + 24, _options, "Inventory", 190, 100);
    image_speed = 0;
    exit;
}

// Do not move the field character while any menu is open.
if (instance_exists(oMenu))
{
    image_speed = 0;
    exit;
}

var _inputH = keyboard_check(vk_right) - keyboard_check(vk_left);
var _inputV = keyboard_check(vk_down) - keyboard_check(vk_up);
var _inputD = point_direction(0, 0, _inputH, _inputV);
var _inputM = point_distance(0, 0, _inputH, _inputV);

if (_inputM != 0)
{
    direction = _inputD;
    image_speed = 1;
}
else
{
    image_speed = 0;
    animIndex = 0;
}

FourDirectionAnimate();
x += lengthdir_x(spdWalk * _inputM, _inputD);
y += lengthdir_y(spdWalk * _inputM, _inputD);
