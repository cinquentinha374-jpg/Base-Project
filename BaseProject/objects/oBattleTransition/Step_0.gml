timer++;

if (mode == "enter")
{
    // Finish the transition and enter the existing battle system.
    if (timer >= totalFrames)
    {
        global.inBattleTransition = true;

        instance_create_depth
        (
            camera_get_view_x(view_camera[0]),
            camera_get_view_y(view_camera[0]),
            -9999,
            oBattle,
            {
                enemies: enemies,
                creator: creator,
                battleBackground: battleBackground,
                encounterEnemy: encounterEnemy
            }
        );

        instance_destroy();
    }
}
else if (mode == "exit")
{
    // Once the screen is completely black, remove the defeated map enemy
    // and put the player back exactly where the encounter started.
    if (!exitCleanupDone && timer >= exitCloseFrames)
    {
        exitCleanupDone = true;

        if (instance_exists(defeatedEnemy))
        {
            with (defeatedEnemy) instance_destroy();
        }

        if (instance_exists(creator))
        {
            creator.x = returnX;
            creator.y = returnY;
        }
    }

    // Reveal the map after the cleanup has happened.
    if (timer >= exitTotalFrames)
    {
        global.inBattleTransition = false;
        instance_destroy();
    }
}
