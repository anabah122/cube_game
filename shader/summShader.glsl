
#ifdef PIXEL

uniform Image img2;     
//uniform Image img3;    

vec4 effect(vec4 _color, Image img1, vec2 uv, vec2 sc) {
    
    vec4 tex1 = Texel( img1 , uv ) ;
    vec4 tex2 = Texel( img2 , uv ) ;
    //vec4 tex3 = Texel( img3 , uv ) ;

    vec4 color = tex1;
    if( tex2.a>0.0 ) color = tex2 ;
    //color += tex3 ;

    color = clamp( color , 0.0, 1.0 );

    return color;
}

#endif
