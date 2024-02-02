package boids

import SDL "vendor:sdl2"
import Image "vendor:sdl2/image"


render_init :: proc() -> (^SDL.Window, ^SDL.Renderer) {
    sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
    assert(sdl_init_error == 0, SDL.GetErrorString())

    window := SDL.CreateWindow(
        "Squoids",
        SDL.WINDOWPOS_CENTERED,
        SDL.WINDOWPOS_CENTERED,
        window_width,
        window_height,
        SDL.WINDOW_SHOWN,
    )

    assert(window != nil, SDL.GetErrorString())
    renderer := SDL.CreateRenderer(window, -1, nil)
    assert(renderer != nil, SDL.GetErrorString())


    return window, renderer

}

load_textures :: proc(renderer: ^SDL.Renderer, images: [3]cstring) -> ([3]^SDL.Texture) {
    textures: [3]^SDL.Texture

    for path, i in images {
        textures[i] = Image.LoadTexture(renderer, path)
        assert(textures[i] != nil, SDL.GetErrorString())
    }

    return textures
}

cleanup :: proc(window: ^SDL.Window, renderer: ^SDL.Renderer) {
    SDL.DestroyRenderer(renderer)
    SDL.DestroyWindow(window)
    SDL.Quit()
}

