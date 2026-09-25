function NewEncounter(_enemies, _bg, _player = noone, _enemyInstance = noone)
{
    // Avoid triggering multiple encounters while the player is touching an enemy.
    if (variable_global_exists("inBattleTransition") && global.inBattleTransition) exit;

    global.inBattleTransition = true;

    // Play the encounter transition first. The battle is created when it ends.
    instance_create_depth
    (
        camera_get_view_x(view_camera[0]),
        camera_get_view_y(view_camera[0]),
        -100000,
        oBattleTransition,
        {
            enemies: _enemies,
            battleBackground: _bg,
            creator: _player,
            encounterEnemy: _enemyInstance
        }
    );
}

function BattleChangeHP(_target, _amount, _AliveDeadOrEither = 0)
{
	//_AliveDeadOrEither: 0 = alive only, 1 = dead only, 2 = any
	var _failed = false;
	if (_AliveDeadOrEither == 0) && (_target.hp <= 0) _failed = true;
	if (_AliveDeadOrEither == 1) && (_target.hp > 0) _failed = true;
	
	var _col = c_white;
	if (_amount > 0) _col = c_lime;
	if (_failed)
	{
		_col = c_white;
		_amount = "failed";
	}
	instance_create_depth
	(
		_target.x,
		_target.y,
		_target.depth-1,
		oBattleFloatingText,
		{font: fnM5x7, col: _col, text: string(_amount)}
	);
	if (!_failed) _target.hp = clamp(_target.hp + _amount, 0, _target.hpMax);
}

function BattleChangeMP(_target, _amount, _AliveDeadOrEither = 0)
{
	//_AliveDeadOrEither: 0 = alive only, 1 = dead only, 2 = any
	var _failed = false;
	if (_AliveDeadOrEither == 0) && (_target.hp <= 0) _failed = true;
	if (_AliveDeadOrEither == 1) && (_target.hp > 0) _failed = true;
	
	var _col = c_white;
	if (_amount > 0) _col = c_lime;
	if (_failed)
	{
		_col = c_white;
		_amount = "failed";
	}
	instance_create_depth
	(
		_target.x,
		_target.y,
		_target.depth-1,
		oBattleFloatingText,
		{font: fnM5x7, col: _col, text: string(_amount)}
	);
	if (!_failed) _target.hp = clamp(_target.hp + _amount, 0, _target.hpMax);
}
