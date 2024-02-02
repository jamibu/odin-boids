package neighbours 

// import "core:math/linalg"
// 
// KDTree :: struct {
//     root: ^KDTreeNode,
// }
// 
// KDTreeNode :: struct {
//     point: linalg.Vector2f32,
//     left: ^KDTreeNode,
//     right: ^KDTreeNode,
// }
// 
// create :: proc(boids: [dynamic]^Boid) -> KDTree {
//     return KDTree{}
// }
// 
// insert :: proc(tree: ^KDTree, boid: Boid) {}
// 
// display :: proc(tree: ^KDTree) {}
// 
// nearest_neighbor :: proc(node: ^KDTreeNode, target: linalg.Vector2f32, depth: int) -> ^KDTreeNode {
//     next_branch: ^KDTreeNode
//     other_branch: ^KDTreeNode
//     if target[depth % 2] < node.point[depth % 2] {
//         next_branch = node.left
//         other_branch = node.right
//     } else {
//         next_branch = node.left
//         other_branch = node.right
//     }
// 
//     temp := nearest_neighbor(next_branch, target, depth + 1)
//     best := closest(temp, node, target)
// 
//     radius_squared := calc_radius_squared(target, best.point)
//     dist := target[depth % 2] - node.point[depth % 2]
//     
//     if (radius_squared >= dist * dist) {
//         temp = nearest_neighbor(other_branch, target, depth + 1)
//         best = closest(temp, best, target)
//     }
// 
//     return best
// }
// 
// closest :: proc(node1: ^KDTreeNode, node2: ^KDTreeNode, target: linalg.Vector2f32) -> ^KDTreeNode {
//     dist1 := calc_radius_squared(target, node1.point)
//     dist2 := calc_radius_squared(target, node2.point)
//     if dist1 < dist2 {
//         return node1
//     } else {
//         return node2
//     }
// }
// 
// calc_radius_squared :: proc(point1: linalg.Vector2f32, point2: linalg.Vector2f32) -> f32 {
//     diff := point2 - point1
//     diff_squared := diff*diff 
// 
//     radius_squared: f32
//     for dim in diff_squared {
//         radius_squared  += dim
//     }
//     return radius_squared
// }
// 
// 
