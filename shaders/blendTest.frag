#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;   // GL_TEXTURE0  (sprite)
uniform sampler2D mask;   // GL_TEXTURE1  (lighting)

vec3 overlay(vec3 base, vec3 mask) {
    vec3 low  = 2.0 * base * mask;
    vec3 high = 1.0 - 2.0 * (1.0 - base) * (1.0 - mask);
    return mix(low, high, step(0.5, base));
}

void main() {
    vec4 b = texture2D(texture,  v_texCoord);
    vec4 m = texture2D(mask,  v_texCoord);

    // Use mask alpha as intensity (optional)
    //vec3 blended = overlay(b.rgb, m.rgb) * m.a + b.rgb * (1.0 - m.a);
    //gl_FragColor = vec4(blended, b.a)*v_color;
	// b.r = m.a;
    // gl_FragColor = b*v_color;
	gl_FragColor.rg = textureSize(mask,0)/255./10.;
	gl_FragColor.ba = vec2(0.,1.);
}