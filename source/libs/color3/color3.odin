package color3

import raylib "vendor:raylib"

_new_with_alpha :: proc(r, g, b: u8, a: f32) -> raylib.Color {
    return raylib.Color{r, g, b, u8(a * 255)}
}

_new_no_alpha :: proc(r, g, b: u8) -> raylib.Color {
    return raylib.Color{r, g, b, 255}
}

new :: proc { _new_with_alpha, _new_no_alpha }