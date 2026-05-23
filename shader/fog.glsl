#ifdef VERTEX

vec4 position(mat4 _t, vec4 vpos) {
    return _t * vpos;
}

#endif


#ifdef PIXEL

uniform vec3 lightPos;
uniform vec3 lightColor;
uniform vec3 camPos;
uniform Image posTex;

float fogEnd = 400.0;
float fogStart = 100.0;
float heightFogDensity = 0.01;

vec3 fogColor = vec3(0.1, 0.1, 0.15);

vec4 effect(vec4 color, Image _tex, vec2 texUv, vec2 screen_coords) {

    if (Texel(_tex, texUv).a < 0.5) discard;
    vec3 wpos = Texel(posTex, texUv).xyz;

    vec3 up = vec3(0, 1, 0);
    vec3 lpos = normalize(lightPos);
    float lightMod = clamp(dot(up, lpos) + 0.1, 0.0, 1.0);

    vec3 d = wpos - camPos;
    float dist = length(d.xz);
    vec3 viewDir = normalize(d);

    float distFog   = clamp((dist - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
    float heightFog = clamp((camPos.y - wpos.y) * heightFogDensity, 0.0, 0.3);
    float fogAmount = clamp(1.0 - (1.0 - distFog) * (1.0 - heightFog), 0.0, 1.0);

    float sunEffect = pow(max(dot(viewDir, lpos), 0.0), 8.0);
    vec3 finalFogColor = mix(fogColor, lightColor, sunEffect);

    return vec4(finalFogColor, fogAmount);
}

#endif
