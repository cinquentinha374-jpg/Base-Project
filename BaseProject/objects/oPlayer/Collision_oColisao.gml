// --- Colisão Horizontal ---
hsp = 0;
vsp = 0;
if (place_meeting(x + hsp, y, oColisao)) {
    while (!place_meeting(x + sign(hsp), y, oColisao)) {
        x += sign(hsp);
    }
    hsp = 0;
}
x += hsp;

// --- Colisão Vertical ---
if (place_meeting(x, y + vsp, oColisao)) {
    while (!place_meeting(x, y + sign(vsp), oColisao)) {
        y += sign(vsp);
    }
    vsp = 0;
}
y += vsp;