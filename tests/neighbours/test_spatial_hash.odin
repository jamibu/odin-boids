package test_neighbours

import SDL "vendor:sdl2"
import Image "vendor:sdl2/image"
import "core:fmt"
import "core:testing"
import "core:math/linalg"
import "../../boids/neighbours"


when ODIN_TEST {
    expect :: testing.expect
    log :: testing.log
} 

main :: proc() {
    t := testing.T{}

    test_bucket(&t)
    test_nearby(&t)
}


@test
test_bucket :: proc(t: ^testing.T) {
    locations := make([dynamic]linalg.Vector2f32)
    hash := neighbours.create_spatialhash(2, &locations)
    neighbours.hash_insert(&hash, linalg.Vector2f32{1.0, 1.0}, 0)
    neighbours.hash_insert(&hash, linalg.Vector2f32{1.5, 1.5}, 1)
    neighbours.hash_insert(&hash, linalg.Vector2f32{1.0, 2.1}, 2)
    neighbours.hash_insert(&hash, linalg.Vector2f32{2.1, 1.1}, 3)

    expected1 := make([dynamic]int)
    append(&expected1, 0)
    append(&expected1, 1)
    result1 := neighbours.hash_bucket(&hash, linalg.Vector2f32{1.5, 1.5})

    expect(t, len(expected1)==len(result1), "Buckets are different lengths")
    expect(t, all_match(expected1, result1), "Buckets don't match")

    expected2 := make([dynamic]int)
    append(&expected2, 3)
    result2 := neighbours.hash_bucket(&hash, linalg.Vector2f32{2.5, 1.4})

    expect(t, len(expected2)==len(result2), "Buckets are different lengths")
    expect(t, all_match(expected2, result2), "Buckets don't match")
}

@test
test_nearby :: proc(t: ^testing.T) {
    locations := make([dynamic]linalg.Vector2f32)
    hash := neighbours.create_spatialhash(2, &locations)
    neighbours.hash_insert(&hash, linalg.Vector2f32{1.0, 1.0}, 0)
    neighbours.hash_insert(&hash, linalg.Vector2f32{1.5, 1.5}, 1)
    neighbours.hash_insert(&hash, linalg.Vector2f32{1.0, 2.1}, 2)
    neighbours.hash_insert(&hash, linalg.Vector2f32{2.1, 1.1}, 3)

    result1 := neighbours.hash_get_with_nearby(&hash, linalg.Vector2f32{1.0, 1.0})
    expected1 := make([dynamic]int)
    append(&expected1, 0)
    append(&expected1, 1)
    expect(t, all_match(expected1, result1), "Different Nearby")

    result2 := neighbours.hash_get_with_nearby(&hash, linalg.Vector2f32{1.0, 1.1})
    expected2 := make([dynamic]int)
    append(&expected2, 0)
    append(&expected2, 1)
    append(&expected2, 2)
    expect(t, all_match(expected2, result2), "Different Nearby")

    result3 := neighbours.hash_get_with_nearby(&hash, linalg.Vector2f32{1.1, 1.1})
    expected3 := make([dynamic]int)
    append(&expected3, 0)
    append(&expected3, 1)
    append(&expected3, 2)
    append(&expected3, 3)
    expect(t, all_match(expected3, result3), "Different Nearby")
}



all_match :: proc(a: [dynamic]int, b: [dynamic]int) -> bool {
    for val, i in a {
        if (b[i] != val) {
            return false
        }
    }

    return true
}

