/*
    SNEK,,,,,
*/

package main

import "core:fmt"
import "core:math/rand"
import "vendor:raylib"
import "libs/color3"
import "libs/timer"

SNEK_BASE_SPEED: f32 = 0.3
SNEK_SPEED_INCREASE: f32 = 0.02 // faster per apple eaten
SNEK_MIN_SPEED: f32 = 0.05
SNEK_START_LENGTH: int = 4

WINDOW_SIZE_X: i32 = 640
WINDOW_SIZE_Y: i32 = 640

GRID_SIZE: i32 : 20

GRID_INCREMENT_X := WINDOW_SIZE_X / GRID_SIZE
GRID_INCREMENT_Y := WINDOW_SIZE_Y / GRID_SIZE

MAX_HISTORY :: 512

Snake :: struct {
    history: [MAX_HISTORY]raylib.Vector2,
    head:    int,
    length:  int,
}

GameState :: enum {
    Playing,
    Dead,
}

grid:      [GRID_SIZE][GRID_SIZE]bool
snek:      Snake
apple:     raylib.Vector2
state:     GameState
score:     int
highScore: int

Direction :: enum {
    Up,
    Down,
    Left,
    Right,
}

spawnApple :: proc() {
    for {
        x := cast(f32)rand.int31_max(GRID_SIZE)
        y := cast(f32)rand.int31_max(GRID_SIZE)
        if !grid[cast(int)x][cast(int)y] {
            apple = raylib.Vector2{x, y}
            break
        }
    }
}

resetGame :: proc(snekTimer: ^timer.Timer) {
    // clear snake
    snek = Snake{}
    startPos := raylib.Vector2{cast(f32)GRID_SIZE / 2, cast(f32)GRID_SIZE / 2}
    snek.history[0] = startPos
    snek.head = 0
    snek.length = SNEK_START_LENGTH
    score = 0

    // clear grid
    for x in 0..<GRID_SIZE {
        for y in 0..<GRID_SIZE {
            grid[x][y] = false
        }
    }

    snekTimer.interval = SNEK_BASE_SPEED
    state = .Playing
    spawnApple()
}

updateGrid :: proc() {
    for x in 0..<GRID_SIZE {
        for y in 0..<GRID_SIZE {
            grid[x][y] = false
        }
    }
    for i in 0..<snek.length {
        idx := (snek.head - i + MAX_HISTORY) % MAX_HISTORY
        pos := snek.history[idx]
        x := cast(i32)pos.x
        y := cast(i32)pos.y
        if x >= 0 && x < GRID_SIZE && y >= 0 && y < GRID_SIZE {
            grid[x][y] = true
        }
    }
}

updateSnekGraphics :: proc() {
    for x: i32 = 0; x < GRID_SIZE; x += 1 {
        for y: i32 = 0; y < GRID_SIZE; y += 1 {
            if cast(i32)apple.x == x && cast(i32)apple.y == y {
                raylib.DrawRectangle(
                    GRID_INCREMENT_X * x,
                    GRID_INCREMENT_Y * y,
                    GRID_INCREMENT_X,
                    GRID_INCREMENT_Y,
                    color3.new(255, 50, 50),
                )
                continue
            }

            if grid[x][y] {
                headX := cast(i32)snek.history[snek.head].x
                headY := cast(i32)snek.history[snek.head].y
                segColor := color3.new(0, 200, 0)
                if x == headX && y == headY {
                    segColor = color3.new(0, 255, 0)
                }
                raylib.DrawRectangle(
                    GRID_INCREMENT_X * x,
                    GRID_INCREMENT_Y * y,
                    GRID_INCREMENT_X,
                    GRID_INCREMENT_Y,
                    segColor,
                )
            } else {
                rectColor := color3.new(15, 15, 15)
                if (x + y) % 2 == 0 {
                    rectColor = color3.new(20, 20, 20)
                }
                raylib.DrawRectangle(
                    GRID_INCREMENT_X * x,
                    GRID_INCREMENT_Y * y,
                    GRID_INCREMENT_X,
                    GRID_INCREMENT_Y,
                    rectColor,
                )
            }
        }
    }
}

drawDeathScreen :: proc() {
    raylib.DrawRectangle(0, 0, WINDOW_SIZE_X, WINDOW_SIZE_Y, color3.new(0, 0, 0, 0.6))

    titleText: cstring = "YOU DIED"
    titleSize: i32 = 64
    titleWidth := raylib.MeasureText(titleText, titleSize)
    raylib.DrawText(titleText, (WINDOW_SIZE_X - titleWidth) / 2, 180, titleSize, color3.new(255, 50, 50))

    scoreText := fmt.caprintf("Score: %d", score)
    scoreSize: i32 = 32
    scoreWidth := raylib.MeasureText(scoreText, scoreSize)
    raylib.DrawText(scoreText, (WINDOW_SIZE_X - scoreWidth) / 2, 270, scoreSize, color3.new(255, 255, 255))
    delete(scoreText)

    if score >= highScore && score > 0 {
        newBestText: cstring = "NEW BEST!"
        newBestWidth := raylib.MeasureText(newBestText, 24)
        raylib.DrawText(newBestText, (WINDOW_SIZE_X - newBestWidth) / 2, 310, 24, color3.new(255, 220, 0))
    } else if highScore > 0 {
        bestText := fmt.caprintf("Best: %d", highScore)
        bestWidth := raylib.MeasureText(bestText, 24)
        raylib.DrawText(bestText, (WINDOW_SIZE_X - bestWidth) / 2, 310, 24, color3.new(180, 180, 180))
        delete(bestText)
    }

    restartText: cstring = "Press ENTER to play again"
    restartSize: i32 = 24
    restartWidth := raylib.MeasureText(restartText, restartSize)
    raylib.DrawText(restartText, (WINDOW_SIZE_X - restartWidth) / 2, 380, restartSize, color3.new(200, 200, 200))
}

drawHUD :: proc() {
    scoreText := fmt.caprintf("Score: %d", score)
    raylib.DrawText(scoreText, 10, 10, 20, color3.new(255, 255, 255))
    delete(scoreText)

    if highScore > 0 {
        bestText := fmt.caprintf("Best: %d", highScore)
        bestWidth := raylib.MeasureText(bestText, 20)
        raylib.DrawText(bestText, WINDOW_SIZE_X - bestWidth - 10, 10, 20, color3.new(180, 180, 180))
        delete(bestText)
    }
}

move :: proc(pos: raylib.Vector2, dir: Direction) -> raylib.Vector2 {
    switch dir {
    case .Up:    return raylib.Vector2{pos.x, pos.y - 1}
    case .Down:  return raylib.Vector2{pos.x, pos.y + 1}
    case .Left:  return raylib.Vector2{pos.x - 1, pos.y}
    case .Right: return raylib.Vector2{pos.x + 1, pos.y}
    }
    return pos
}

main :: proc() {
    raylib.InitWindow(WINDOW_SIZE_X, WINDOW_SIZE_Y, "Snek")

    snekTimer := timer.new(SNEK_BASE_SPEED)
    direction := Direction.Down
    nextDirection := Direction.Down

    startPos := raylib.Vector2{cast(f32)GRID_SIZE / 2, cast(f32)GRID_SIZE / 2}
    snek.history[0] = startPos
    snek.head = 0
    snek.length = SNEK_START_LENGTH
    state = .Playing
    spawnApple()

    raylib.SetExitKey(.ESCAPE)
    for !raylib.WindowShouldClose() {
        raylib.BeginDrawing()
        raylib.ClearBackground(color3.new(0, 0, 0))

        #partial switch raylib.GetKeyPressed() {
        case .W: if direction != .Down  do nextDirection = .Up
        case .A: if direction != .Right do nextDirection = .Left
        case .S: if direction != .Up    do nextDirection = .Down
        case .D: if direction != .Left  do nextDirection = .Right
        case .ENTER:
            if state == .Dead {
                resetGame(&snekTimer)
                direction = .Down
                nextDirection = .Down
            }
        }

        if state == .Playing {
            if timer.tick(&snekTimer, raylib.GetFrameTime()) {
                direction = nextDirection
                newPos := move(snek.history[snek.head], direction)

                // wall death
                if newPos.x < 0 || newPos.x >= cast(f32)GRID_SIZE ||
                   newPos.y < 0 || newPos.y >= cast(f32)GRID_SIZE {
                    if score > highScore do highScore = score
                    state = .Dead
                } else {
                    // self collision (skip head segment)
                    hitSelf := false
                    for i in 1..<snek.length {
                        idx := (snek.head - i + MAX_HISTORY) % MAX_HISTORY
                        if snek.history[idx] == newPos {
                            hitSelf = true
                            break
                        }
                    }

                    if hitSelf {
                        if score > highScore do highScore = score
                        state = .Dead
                    } else {
                        snek.head = (snek.head + 1) % MAX_HISTORY
                        snek.history[snek.head] = newPos

                        // apple pickup
                        if newPos == apple {
                            score += 1
                            snek.length += 1
                            
                            snekTimer.interval -= SNEK_SPEED_INCREASE
                            if snekTimer.interval < SNEK_MIN_SPEED {
                                snekTimer.interval = SNEK_MIN_SPEED
                            }
                            spawnApple()
                        }
                    }
                }
            }

            updateGrid()
            updateSnekGraphics()
            drawHUD()
        } else if state == .Dead {
            updateSnekGraphics()
            drawDeathScreen()
        }

        raylib.EndDrawing()
    }
}