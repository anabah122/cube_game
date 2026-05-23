varying vec2 vCellUV;
varying vec2 vTexCoord;
varying vec3 exportPos;
varying vec3 vnormal;
varying float exportDepth;

#ifdef VERTEX

attribute vec2 VertexCellUV;
attribute vec3 VertexNormal;

uniform mat4 viewproj;

vec4 position(mat4 _t, vec4 vertex_position) {
    vCellUV   = VertexCellUV;
    vTexCoord = VertexTexCoord.xy;
    exportPos = vertex_position.xyz;
    vnormal  = VertexNormal;
    vec4 vert = viewproj * vertex_position;
    exportDepth = vert.w;
    return vert;
}

#endif

#ifdef PIXEL

uniform vec2  uvOffsets;
uniform float min_alpha;
uniform Image main_tex;
uniform vec3  lightPos;
uniform vec3  lightColor;

float wrap = 0.4;
vec3  ambientColor = vec3(0.4);

void effect() {

    vec2 uv = vCellUV + uvOffsets.x + fract(vTexCoord) * uvOffsets.y;

    vec4 col  = Texel(main_tex, uv);
    if (col.a < min_alpha) discard;

    vec3  lpos     = normalize(lightPos);
    float lightMod = clamp(dot(vec3(0,1,0), lpos) + 0.1, 0.0, 1.0);
    float NdotL   = dot(normalize(vnormal), lpos);
    float diff    = max((NdotL + wrap) / (1.0 + wrap), 0.0) * lightMod;

    vec3 lit = col.rgb * clamp(ambientColor + diff * lightColor, 0.0, 1.0);

    love_Canvases[0] = vec4(lit, col.a);
    love_Canvases[1] = vec4(exportPos, 1.0);
    love_Canvases[2] = vec4((exportDepth + 0.5) * 2.0);
}

#endif
