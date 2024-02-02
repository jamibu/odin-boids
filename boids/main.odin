package boids

import "core:os"
import "core:math"
import "core:math/rand"
import "core:math/linalg/glsl"
import "core:fmt"
import SDL "vendor:sdl2"
import Image "vendor:sdl2/image"

Game :: struct {
	renderer: ^SDL.Renderer,
	keyboard: []u8,
	time: f64,
	dt: f64,
}

// window_width: i32 = 1280
// window_height: i32 = 720
window_width: i32 = 1920
window_height: i32 = 1080

get_time :: proc() -> f64 {
	return f64(SDL.GetPerformanceCounter()) * 1000 / f64(SDL.GetPerformanceFrequency())
}

run_start := get_time()
run_time: f64

distance_time: f64
neighbor_time: f64
steering_time: f64
location_time: f64

main :: proc() {
    mode: string
    if len(os.args) == 1 {
        mode = "standard"
    } else {
        mode = os.args[1]
    }

    window, renderer := render_init()
    defer cleanup(window, renderer) // Ensure window etc are deleted

    images := [3]cstring{
        "assets/CuteSquid.png",
        "assets/CuteSquid2.png",
        "assets/SquidEmote.png",
    }

    textures := load_textures(renderer, images)

    // Setup
    tickrate := 240.0
    ticktime := 1000.0 / tickrate

    game := Game{
        renderer = renderer,
        time = get_time(),
        dt = ticktime,
    }

    flock_settings := get_settings(mode)
    flock := create_flock(&flock_settings, textures)
    defer cleanup_flock(&flock)

    // Create empty predators

    dt := 0.0
    quit := false

    frames := 0
    fps: f32
    fps_time: f64
    starttime := get_time()

    update_time: f64
    render_time: f64

    // Game Loop
    for !quit {
        // Update frame timing
        time := get_time()
        dt += time - game.time

        // Input
        quit = check_quit()
        game.keyboard = SDL.GetKeyboardStateAsSlice()

        // Update
        game.time = time

        update_start := get_time()
        for dt >= ticktime {
            dt -= ticktime
            update_flock(&flock, &flock_settings, f32(game.dt))
        }
        update_time += get_time() - update_start

        //Render
        render_start := get_time()
        SDL.SetRenderDrawColor(renderer, 1, 10, 25, 0)
        SDL.RenderClear(renderer)

        for _, i in flock.boids.loc {
            render_boid(&flock.boids, i, &game)
            // Avoid predators (turn?)

            // update_predators()
            // Go towards centre of mass of what we see
            // Do separation for other predators
            // if a predator touches a boid turn it to a predator
        }
        SDL.RenderPresent(renderer)
        render_time += get_time() - render_start

        // Simple FPS counter to stdout
        frames += 1
        fps_time = (time - starttime) / 1000.0
        if (fps_time > 1) {
            starttime = time
            fps = f32(frames) / f32(fps_time)
            fmt.println("FPS: ", fps)
            frames = 0
        }
    }
    run_time = get_time() - run_start
    fmt.println("RUNTIME -", run_time / 1000)
    fmt.println("Update:", 100 * update_time / run_time)
    fmt.println("  - Distance:", 100 * distance_time / run_time)
    fmt.println("  - Neighbor:", 100 * neighbor_time / run_time)
    fmt.println("  - Steering:", 100 * steering_time / run_time)
    fmt.println("  - Location:", 100 * location_time / run_time)
    fmt.println("Render:", 100 * render_time / run_time)
}

check_quit :: proc() -> bool {
    event: SDL.Event
    for SDL.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            return true
        case .KEYDOWN:
            if event.key.keysym.scancode == SDL.SCANCODE_ESCAPE {
                return true
            }
        }
    }

    return false
}

