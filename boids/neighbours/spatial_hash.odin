package neighbours 

import "core:fmt"
import "core:math"
import "core:math/linalg"


SpatialHash :: struct {
    cell_size: int,
    contents: map[[2]int][dynamic]int,
}

hash_function :: proc(cell_size: int, point: linalg.Vector2f32) -> [2]int {
    hashed := point / f32(cell_size)
    key := [2]int{
        int(hashed[0]),
        int(hashed[1]),
    }
    return key
}

create_spatialhash :: proc(
    cell_size: int,
    width: int,
    height: int,
    points: ^[dynamic]linalg.Vector2f32,
) -> SpatialHash {
    hash := SpatialHash {
        cell_size=cell_size,
        contents=make(map[[2]int][dynamic]int),
    }

    for i:=-cell_size; i<width+cell_size; i+=cell_size {
        for j:=-cell_size; j<height+cell_size; j+=cell_size {
            hash.contents[[2]int{i, j}] = make([dynamic]int, )
        }
    }

    return hash
}

hash_insert :: proc(hash: ^SpatialHash, point: linalg.Vector2f32, idx: int) -> [2]int {
    key := hash_function(hash.cell_size, point)
    if !(key in hash.contents) {
        hash.contents[key] = make([dynamic]int)
    }
    append(&hash.contents[key], idx)

    return key
}

hash_bucket :: proc(
    hash: ^SpatialHash,
    point: linalg.Vector2f32,
) -> [dynamic]int {
    key := hash_function(hash.cell_size, point)
    bucket: [dynamic]int
    if (key in hash.contents) {
        bucket = hash.contents[key]
    }

    return bucket
}

hash_get :: proc(hash: ^SpatialHash, key: [2]int) -> [dynamic]int {
    bucket: [dynamic]int
    if (key in hash.contents) {
        bucket = hash.contents[key]
    }

    return bucket
}

// hash_bucket :: proc(hash: ^SpatialHash, point: linalg.Vector2f32) {}

hash_get_with_nearby :: proc(
    hash: ^SpatialHash,
    key: [2]int,
    point: linalg.Vector2f32,
    nearby: ^[dynamic]int,
) {
    clear(nearby)
    append(nearby, ..hash_get(hash, key)[:])
    append(nearby, ..hash.contents[[2]int{key[0], key[1] + 1}][:])
    append(nearby, ..hash.contents[[2]int{key[0], key[1] - 1}][:])
    append(nearby, ..hash.contents[[2]int{key[0] + 1, key[1]}][:])
    append(nearby, ..hash.contents[[2]int{key[0] + 1, key[1] + 1}][:])
    append(nearby, ..hash.contents[[2]int{key[0] + 1, key[1] - 1}][:])
    append(nearby, ..hash.contents[[2]int{key[0] - 1, key[1]}][:])
    append(nearby, ..hash.contents[[2]int{key[0] - 1, key[1] + 1}][:])
    append(nearby, ..hash.contents[[2]int{key[0] - 1, key[1] - 1}][:])
}

hash_update :: proc(
    hash: ^SpatialHash,
    key: [2]int,
    point: linalg.Vector2f32,
    idx: int,
) {
    new_key := hash_function(hash.cell_size, point)

    if new_key == key {
        return
    }

    hash_remove(hash, key, point, idx)
    append(&hash.contents[key], idx)
}

hash_remove :: proc(
    hash: ^SpatialHash,
    key: [2]int,
    point: linalg.Vector2f32,
    idx: int,
) {
    bucket_idx: int
    for val, i in hash.contents[key] {
        if val == idx {
            bucket_idx = i
            break
        }
    }
    unordered_remove(&hash.contents[key], bucket_idx)
}

hash_clear_buckets :: proc(
    hash: ^SpatialHash,
) {
    for key, bucket in hash.contents {
        clear(&hash.contents[key])
    }
}

// TODO: Rehash when a boid moves from one bucket to another
    // Check if key has changed after boids movement is applied
    // Remove from current bucket if it is in a new bucket
    // Add to new bucket
