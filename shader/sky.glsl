varying vec3 fpos;

#ifdef VERTEX

uniform mat4 viewproj;
uniform vec3 camPos;

vec4 position(mat4 _t, vec4 vpos) {
    fpos = vpos.xyz+camPos ;
    return viewproj * vec4(fpos, 1.0);
}

#endif

#ifdef PIXEL


uniform vec3 lightPos;
uniform vec3 camPos;

vec3 color0 = vec3(1.000, 0.631, 0.180); // #ffa12e
vec3 color1 = vec3(0.804, 0.498, 0.196); // #2173a3ff
vec3 color2 = vec3(0.282, 0.239, 0.545); // #003566ff
vec3 color3 = vec3(0.114, 0.110, 0.231); // #01001fff
vec4 stops =  vec4( 0.1, 1, 4, 4 );

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) 
{
    vec3 dir = normalize(fpos - camPos);
    float t = dot(dir, normalize(lightPos));
    t = t * -0.5 + 0.5; // [0,1]: 0 = lightPos, 1 = противоположность

    stops = normalize( stops );

    vec3 c;
    if (t < stops.x) {
        c = mix(color0, color1, (t) / (stops.x));
    } else if (t < stops.y) {
        c = mix(color1, color2, (t - stops.x) / (stops.y - stops.x));
    } else if (t < stops.z) {
        c = mix(color2, color3, (t - stops.y) / (stops.z - stops.y));
    } else {
        c = color3;
    }
        
    return vec4(c, 1.0);
}

#endif
