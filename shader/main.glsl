
varying vec3  vNormal;
varying vec2  vLocalUV;
varying vec4  vTile; // start xy and size xy 
varying float vLight;

#ifdef VERTEX

attribute vec3 VertexNormal;
attribute vec4 VertexTile;

uniform mat4 viewproj;
uniform mat4 transform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vNormal  = VertexNormal;
    vLocalUV = VertexTexCoord.xy;
    vTile    = VertexTile;
    float d  = dot(normalize(VertexNormal), normalize(vec3(0.5, 1.0, 0.3)));
    vLight   = 0.55 + 0.45 * max(d, 0.0);
    return viewproj * transform * vertex_position;
}

#endif

#ifdef PIXEL

uniform float min_alpha;

vec4 effect(vec4 color, Image tex, vec2 texUv, vec2 screen_coords) {

    vec2 uv = vTile.xy + fract(vLocalUV) * vTile.zw;
    vec4 c  = Texel(tex, uv);
    if (c.a < min_alpha) discard;
    return vec4(c.rgb * vLight, c.a);
}

#endif
