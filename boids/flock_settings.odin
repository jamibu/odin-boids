package boids

import "core:fmt"

FlockSettings :: struct {
    turn_factor: f32,
    visual_range: f32,
    protected_range: f32,
    centering_factor: f32,
    avoid_factor: f32,
    min_speed: f32,
    max_speed: f32,
    matching_factor: f32,
    margin: f32,
    max_bias: f32,
    bias_increment: f32,
    bias_val: f32,
    num_boids: i32,
    mode: Mode,
}

Mode :: enum {
    Standard,
    Group,
    Chasings,
}

get_settings :: proc(mode: string) -> FlockSettings {
    flock_settings: FlockSettings

    switch mode {
        case "standard":
            flock_settings = FlockSettings {
                turn_factor=0.002,
                visual_range=50 * 50,
                protected_range=20 * 20,
                centering_factor=0.00003,
                avoid_factor=0.001,
                matching_factor=0.005,
                min_speed=0.15,
                max_speed=0.25,
                margin=100,
                max_bias=0.0002,
                bias_increment=0.0000003,
                num_boids=1000,
                mode=.Standard,
            }
        case "groups":
            flock_settings = FlockSettings {
                turn_factor=0.002,
                visual_range=70 * 70,
                protected_range=20 * 20,
                centering_factor=0.00002,
                avoid_factor=0.001,
                matching_factor=0.010,
                min_speed=0.15,
                max_speed=0.25,
                margin=100,
                max_bias=0.0002,
                bias_increment=0.0000003,
                num_boids=600,
                mode=.Group,
            }
        case "chasings":
            flock_settings = FlockSettings {
                turn_factor=0.002,
                visual_range=100,
                protected_range=20,
                centering_factor=0.00003,
                avoid_factor=0.001,
                matching_factor=0.01,
                min_speed=0.15,
                max_speed=0.25,
                margin=100,
                max_bias=0.0002,
                bias_increment=0.0000003,
                num_boids=300,
                mode=.Chasings,
            }
        case:
            fmt.println("Unsupported mode: ", mode)
    }

    return flock_settings
}
