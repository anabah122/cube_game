varying vec2 vCellUV;
varying vec2 vTexCoord;
varying vec3 exportPos;
varying vec3 vnormal;
varying float exportDepth;

const vec3 NORMAL_TABLE[8] = vec3[8](
    vec3( 1.0,  0.0,  0.0),   // 0 +X
    vec3(-1.0,  0.0,  0.0),   // 1 -X
    vec3( 0.0,  1.0,  0.0),   // 2 +Y
    vec3( 0.0, -1.0,  0.0),   // 3 -Y
    vec3( 0.0,  0.0,  1.0),   // 4 +Z
    vec3( 0.0,  0.0, -1.0),   // 5 -Z
    vec3( 0.7071, 0.0,  0.7071), // 6 diag +X+Z
    vec3( 0.7071, 0.0, -0.7071)  // 7 diag +X-Z
);

#ifdef VERTEX

attribute float VertexMatIdx;
attribute vec4  VertexNormal;

uniform mat4 viewproj;
uniform vec2  cellUV;   // atlas cell size in UV (x = cell/W, y = cell/H)
uniform float atlasCols; // tiles per row

vec4 position(mat4 _t, vec4 vertex_position) {
    float idx = VertexMatIdx;
    float col = mod(idx, atlasCols);
    float row = floor(idx / atlasCols);
    vCellUV   = vec2(col, row) * cellUV;
    vTexCoord = VertexTexCoord.xy;
    exportPos = vertex_position.xyz;
    int ni = int(VertexNormal.x * 255.0 + 0.5);
    vnormal  = NORMAL_TABLE[ni];
    vec4 vert = viewproj * vertex_position;
    exportDepth = vert.w;
    return vert;
}

#endif

#ifdef PIXEL

uniform vec2  uvOffsets;
//uniform float min_alpha;
uniform Image main_tex;
uniform vec3  lightPos;
uniform vec3  lightColor;
uniform vec3  camPos;

float wrap = 0.4;
vec3  ambientColor = vec3(0.4);

const float fogStart = 100.0;
const float fogEnd   = 400.0;
const float heightFogDensity = 0.01;
const vec3  fogColor = vec3(0.1, 0.1, 0.15);


vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{

    vec2 uv = vCellUV + uvOffsets.xx + fract(vTexCoord) * uvOffsets.yy;

    vec4 col  = Texel(main_tex, uv);
    //if (col.a < min_alpha) discard;

    vec3  lpos     = normalize(lightPos);
    float lightMod = clamp(dot(vec3(0,1,0), lpos) + 0.1, 0.0, 1.0);
    float NdotL   = dot(normalize(vnormal), lpos);
    float diff    = max((NdotL + wrap) / (1.0 + wrap), 0.0) * lightMod;

    vec3 lit = col.rgb * clamp(ambientColor + diff * lightColor, 0.0, 1.0);

    vec3  d         = exportPos - camPos;
    float dist      = length(d.xz);
    vec3  viewDir   = normalize(d);
    float distFog   = clamp((dist - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
    float heightFog = clamp((camPos.y - exportPos.y) * heightFogDensity, 0.0, 0.3);
    float fogAmount = clamp(1.0 - (1.0 - distFog) * (1.0 - heightFog), 0.0, 1.0);
    float sunEffect = pow(max(dot(viewDir, lpos), 0.0), 8.0);
    vec3  finalFog  = mix(fogColor, lightColor, sunEffect);

    return vec4(mix(lit, finalFog, fogAmount), 1.0);
}

#endif
