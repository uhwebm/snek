package timer

Timer :: struct {
    interval: f32,
    elapsed:  f32,
}

new :: proc(interval: f32) -> Timer {
    return Timer{interval, 0.0}
}

tick :: proc(t: ^Timer, dt: f32) -> bool {
    t.elapsed += dt
    if t.elapsed >= t.interval {
        t.elapsed = 0.0
        return true
    }
    return false
}