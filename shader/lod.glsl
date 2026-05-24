varying vec3 exportPos;

#ifdef VERTEX

uniform mat4 viewproj;

vec4 position(mat4 _t, vec4 vertex_position) {
    exportPos = vertex_position.xyz;
    return viewproj * vertex_position;
}

#endif

#ifdef PIXEL

uniform vec3 camPos;
uniform vec3 lightPos;
uniform vec3 lightColor;
uniform float lodStart;
uniform float lodEnd;

const float fogStart = 100.0;
const float fogEnd   = 400.0;
const float heightFogDensity = 0.01;
const vec3  fogColor = vec3(0.1, 0.1, 0.15);
const vec3  baseColor = vec3(0.35, 0.4, 0.35);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec3  d         = exportPos - camPos;
    float dist      = length(d.xz);
    vec3  viewDir   = normalize(d);
    vec3  lpos      = normalize(lightPos);
    float distFog   = clamp((dist - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
    float heightFog = clamp((camPos.y - exportPos.y) * heightFogDensity, 0.0, 0.3);
    float fogAmount = clamp(1.0 - (1.0 - distFog) * (1.0 - heightFog), 0.0, 1.0);
    float sunEffect = pow(max(dot(viewDir, lpos), 0.0), 8.0);
    vec3  finalFog  = mix(fogColor, lightColor, sunEffect);

    float a = smoothstep(lodStart, lodEnd, dist);
    return vec4(mix(baseColor, finalFog, fogAmount), a);
}

#endif
