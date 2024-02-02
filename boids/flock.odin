package boids 

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:math/linalg"
import SDL "vendor:sdl2"
import Image "vendor:sdl2/image"

import "/neighbours"


Flock :: struct {
    boids: Boids,
    distances: [][dynamic]f32,
    neighbors: [dynamic]int,
    too_close: [dynamic]int,
}

BoidBias :: enum {
    Left,
    Right,
    // Up,
    // Down,
    None,
}

Boids :: struct {
    loc: [dynamic]linalg.Vector2f32,
    vel: [dynamic]linalg.Vector2f32,
    bias: [dynamic]BoidBias,
    bias_val: [dynamic]f32,
    texture: [dynamic]^SDL.Texture,
}


add_boid :: proc(
    boids: ^Boids,
    loc: linalg.Vector2f32,
    vel: linalg.Vector2f32,
    bias: BoidBias,
    bias_val: f32,
    texture: ^SDL.Texture,
) {
    append(&boids.loc, loc)
    append(&boids.vel, vel)
    append(&boids.bias, bias)
    append(&boids.bias_val, bias_val)
    append(&boids.texture, texture)
}


create_flock :: proc(settings: ^FlockSettings, textures: [3]^SDL.Texture) -> Flock {
    bias: BoidBias
    texture: ^SDL.Texture

    boids := Boids {
        loc=make([dynamic]linalg.Vector2f32),
        vel=make([dynamic]linalg.Vector2f32),
        bias=make([dynamic]BoidBias),
        texture=make([dynamic]^SDL.Texture),
    }

    spawn_x := i32(window_width) / 2 - settings.num_boids*4 / 2 
    spawn_y := i32(window_height) / 2 - settings.num_boids*3 / 2
    for i in 1..=settings.num_boids {
        switch rand.int_max(3) {
        case 0:
            bias = BoidBias.Left
            texture = textures[0] 
        case 1:
            bias = BoidBias.Right
            texture = textures[1] 
        // case 2:
        //     bias = BoidBias.Up
        // case 3:
        //     bias = BoidBias.Down
        case:
            bias = BoidBias.None
            texture = textures[2] 
        }

        add_boid(
            &boids,
            linalg.Vector2f32{f32(spawn_x), f32(spawn_y)},
            linalg.Vector2f32{settings.min_speed, settings.min_speed},
            bias,
            settings.bias_val,
            texture,
        )

        spawn_x += 4
        spawn_y += 3
    }

    distances := make([][dynamic]f32, len(boids.loc))
    neighbors := make([dynamic]int, 0, len(boids.loc))
    too_close := make([dynamic]int, 0, len(boids.loc))

    return Flock{
        boids=boids,
        distances=distances,
        neighbors=neighbors,
        too_close=too_close,
    }
}

cleanup_flock :: proc(flock: ^Flock) {
    delete(flock.boids.loc) 
    delete(flock.boids.vel) 
    delete(flock.boids.bias) 
    delete(flock.boids.bias_val) 
    delete(flock.boids.texture) 
    delete(flock.distances)
    delete(flock.neighbors)
    delete(flock.too_close)
}

update_flock :: proc(flock: ^Flock, settings: ^FlockSettings, dt: f32) {
    distance_start := get_time()
    calc_distance(&flock.boids.loc, &flock.distances)
    distance_time += get_time() - distance_start
    for index in 0..<len(flock.boids.loc) {
        neighbor_start := get_time()
        find_neighbors(
            index,
            &flock.distances,
            &flock.neighbors,
            &flock.too_close,
            settings.visual_range,
            settings.protected_range,
        )
        neighbor_time += get_time() - neighbor_start

        steering_start := get_time()
        steering(flock, index, settings)
        steering_time += get_time() - steering_start
        // speed := math.sqrt_f32(flock.boids[index].vel[0] * flock.boids[index].vel[0] + flock.boids[index].vel[1] * flock.boids[index].vel[1])

        location_start := get_time()
        speed := linalg.length(flock.boids.vel[index])
        if speed > settings.max_speed {
             flock.boids.vel[index] = flock.boids.vel[index] / speed * settings.max_speed
        }
        if speed < settings.min_speed {
             flock.boids.vel[index] = flock.boids.vel[index] / speed * settings.min_speed
        }
        flock.boids.loc[index] += flock.boids.vel[index] * f32(dt)
        location_time += get_time() - location_start
    }
}

steering :: proc(flock: ^Flock, index: int, settings: ^FlockSettings) {
    separation(&flock.boids, index, &flock.too_close, settings.avoid_factor)
    if settings.mode == .Group {
       avoid(&flock.boids, index, &flock.neighbors, settings.avoid_factor*0.05)
    }
    alignment(&flock.boids, index, &flock.neighbors, settings.matching_factor, settings.mode)
    cohesion(&flock.boids, index, &flock.neighbors, settings.centering_factor, settings.mode)
    turn_if_edge(
        &flock.boids,
        index,
        settings.margin, 
        f32(window_width) - settings.margin,
        settings.margin,
        f32(window_height) - settings.margin,
        settings.turn_factor,
    )
    update_bias(&flock.boids, index, settings.max_bias, settings.bias_increment)
    apply_bias(&flock.boids, index)
}

render_boid :: proc(boids: ^Boids, boid: int, game: ^Game) {
    angle := linalg.atan2(boids.vel[boid][1], boids.vel[boid][0])
    angle = math.to_degrees_f32(angle) + 90

    #partial switch boids.bias[boid] {
        case .Left:
            rect := SDL.Rect {
                x=i32(boids.loc[boid][0]),
                y=i32(boids.loc[boid][1]),
                w=16,
                h=16,
            }
            SDL.RenderCopyEx(game.renderer, boids.texture[boid], nil, &rect, f64(angle), nil, nil)
        case .Right:
            rect := SDL.Rect {
                x=i32(boids.loc[boid][0]),
                y=i32(boids.loc[boid][1]),
                w=16,
                h=16,
            }
            SDL.RenderCopyEx(game.renderer, boids.texture[boid], nil, &rect, f64(angle), nil, nil)
        case .None:
            rect := SDL.Rect {
                x=i32(boids.loc[boid][0]),
                y=i32(boids.loc[boid][1]),
                w=20,
                h=20,
            }
            SDL.RenderCopyEx(game.renderer, boids.texture[boid], nil, &rect, f64(angle), nil, nil)
        // case .None, .Up, .Down:
        //     SDL.SetRenderDrawColor(game.renderer, 45, 142, 252, 255)
    }
}

calc_distance :: proc(
    boid_locs: ^[dynamic]linalg.Vector2f32,
    distances: ^[][dynamic]f32,
) {

    diffx: f32
    diffy: f32
    distance: f32

    for i in 0..<len(boid_locs) {
        resize(&distances[i], len(boid_locs))
    }

    for i in 0..<len(boid_locs) {
        for j in i..<len(boid_locs) {
            // Squared distance to save doing sqrt. Make sure to compare to squared radii
            diffx = boid_locs[i][0] - boid_locs[j][0]
            diffy = boid_locs[i][1] - boid_locs[j][1]

            distance = diffx*diffx + diffy*diffy

            distances[i][j] = distance
        }
    }
}

find_neighbors :: proc(
    boid: int,
    distances: ^[][dynamic]f32,
    neighbors: ^[dynamic]int,
    too_close: ^[dynamic]int,
    visible_radius: f32,
    protected_radius: f32,
){
    // TODO: Pull this out into steering function or above
    clear(neighbors)
    clear(too_close)
    distance: f32
    for i in 0..<len(distances) {
        if i > boid {
            distance = distances[boid][i]
        } else if i < boid {
            distance = distances[i][boid]
        } else {
            continue
        }

        if distance <= visible_radius {
            append(neighbors, i)

            if distance <= protected_radius{
                append(too_close, i)
            }
        }
    }
}

avoid :: proc(
    boids: ^Boids,
    boid: int,
    neighbors: ^[dynamic]int,
    avoid_factor: f32,
) {
    close: linalg.Vector2f32
    
    for idx in neighbors {
        if boids.bias[boid] != boids.bias[idx] {
            close += boids.loc[boid] - boids.loc[idx]
        }
    }
    boids.vel[boid] += close * avoid_factor
}

separation :: proc(
    boids: ^Boids,
    boid: int,
    too_close: ^[dynamic]int,
    avoid_factor: f32,
) {
    close: linalg.Vector2f32
    
    for idx in too_close {
        close += boids.loc[boid] - boids.loc[idx]
    }
    boids.vel[boid] += close * avoid_factor
}

avoid_non_group :: proc(
    boids: ^Boids,
    boid: int,
    neighbors: ^[dynamic]int,
    avoid_factor: f32,
) {
    close: linalg.Vector2f32
    
    for idx in neighbors {
        if boids.bias[boid] != boids.bias[idx] {
            close += boids.loc[boid] - boids.loc[idx]
        }
    }
    boids.vel[boid] += close * avoid_factor
}

// avoid_predator :: proc(boids: ^Boids, predators: ^[dynamic]Boid, predator_range: f32) {}

alignment :: proc(
    boids: ^Boids,
    boid: int,
    neighbours: ^[dynamic]int,
    matching_factor: f32,
    mode: Mode,
) {
    num_neighbours := f32(len(neighbours))
    if !(num_neighbours > 0) {
        return
    }

    vel_avg: linalg.Vector2f32
    for index in neighbours {
        if mode == .Group && boids.bias[boid] != boids.bias[index] {
            return
        }
        // apply_change := int(mode != .Group || boids[boid].bias == boids[index].bias)
        // vel_avg += boids[index].vel * f32(apply_change)
        vel_avg += boids.vel[index]
    }

    if (vel_avg == linalg.Vector2f32{0, 0}) {
        return
    }

    vel_avg = vel_avg / num_neighbours

    boids.vel[boid] += (vel_avg - boids.vel[boid]) * matching_factor
}

cohesion :: proc( 
    boids: ^Boids,
    boid: int,
    neighbours: ^[dynamic]int,
    centering_factor: f32,
    mode: Mode,
) {
    num_neighbours := f32(len(neighbours))
    if !(num_neighbours > 0) {
        return
    }

    pos_avg: linalg.Vector2f32
    for index in neighbours {
        if mode == .Group && boids.bias[boid] != boids.bias[index] {
            return
        }
        // apply_change := int(mode != .Group || boids[boid].bias == boids[index].bias)
        // pos_avg += boids[index].loc * f32(apply_change)
        pos_avg += boids.loc[index]
    }

    if (pos_avg == linalg.Vector2f32{0, 0}) {
        return
    }

    pos_avg = pos_avg / num_neighbours

    boids.vel[boid] += (pos_avg - boids.loc[boid]) * centering_factor
}

turn_if_edge :: proc(
    boids: ^Boids,
    boid: int,
    left_margin: f32,
    right_margin: f32,
    top_margin: f32,
    bottom_margin: f32,
    turn_factor: f32,
) {
    if boids.loc[boid][0] < left_margin {
        boids.vel[boid][0] += turn_factor
    }
    if boids.loc[boid][0] > right_margin {
        boids.vel[boid][0] -= turn_factor
    }
    if boids.loc[boid][1] < top_margin {
        boids.vel[boid][1] += turn_factor
    }
    if boids.loc[boid][1] > bottom_margin {
        boids.vel[boid][1] -= turn_factor
    }
}

apply_bias :: proc(boids: ^Boids, boid: int) {
    #partial switch boids.bias[boid] {
    case .Left:
        boids.vel[boid][0] = (1 - boids.bias_val[boid])*boids.vel[boid][0] - boids.bias_val[boid]
    case .Right:
        boids.vel[boid][0] = (1 - boids.bias_val[boid])*boids.vel[boid][0] + boids.bias_val[boid]
    // case .Up:
    //     boid.vy = (1 - boid.bias_val)*boid.vy + (boid.bias_val)
    // case .Down:
    //     boid.vy = (1 - boid.bias_val)*boid.vy + (-boid.bias_val)
    }
}

update_bias :: proc(boids: ^Boids, boid: int, max_bias: f32, bias_increment: f32) {
    #partial switch boids.bias[boid] {
    case .Right:
        if (boids.vel[boid][0] < 0) {
            boids.bias_val[boid] = min(max_bias, boids.bias_val[boid] + bias_increment)
        } else {
            boids.bias_val[boid] = max(bias_increment, boids.bias_val[boid] - bias_increment)
        }
    case .Left:
        if (boids.vel[boid][0] > 0) {
            boids.bias_val[boid] = min(max_bias, boids.bias_val[boid] + bias_increment)
        } else {
            boids.bias_val[boid] = max(bias_increment, boids.bias_val[boid] - bias_increment)
        }
    // case .Down:
    //     if (boid.vy > 0) {
    //         boid.bias_val = min(max_bias, boid.bias_val + bias_increment)
    //     } else {
    //         boid.bias_val = max(bias_increment, boid.bias_val - bias_increment)
    //     }
    // case .Up:
    //     if (boid.vy < 0) {
    //         boid.bias_val = min(max_bias, boid.bias_val + bias_increment)
    //     } else {
    //         boid.bias_val = max(bias_increment, boid.bias_val - bias_increment)
    //     }
    }

}

