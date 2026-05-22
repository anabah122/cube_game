varying vec2 vCellUV;
varying vec2 vTexCoord;

#ifdef VERTEX

attribute vec2 VertexCellUV;

uniform mat4 viewproj;
uniform mat4 transform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vCellUV   = VertexCellUV;
    vTexCoord = VertexTexCoord.xy;
    return viewproj * transform * vertex_position;
}

#endif

#ifdef PIXEL

uniform vec2  uvOffsets;
uniform float min_alpha;

vec4 effect(vec4 color, Image tex, vec2 texUv, vec2 screen_coords) {
    vec2 uv = vCellUV + uvOffsets.x + fract(vTexCoord) * uvOffsets.y;
    vec4 c  = Texel(tex, uv);
    return c;
}

#endif
