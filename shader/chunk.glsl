#ifdef VERTEX

uniform mat4 viewproj;
uniform mat4 transform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return viewproj * transform * vertex_position;
}

#endif
#ifdef PIXEL

vec4 effect(vec4 color, Image tex, vec2 texUv, vec2 screen_coords) {
    return vec4(1.0);
}

#endif
