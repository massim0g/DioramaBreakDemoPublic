#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

uniform vec4 colors[4];

uniform vec4 viewRect;
uniform vec4 gradientRect;

uniform vec2 viewportSize;

uniform bool clampGradient;

uniform int tintMode;

/* Overlay(base, blend) per channel */
vec3 overlay(vec3 base, vec3 blend){
    vec3 low  = 2.*base*blend;
    vec3 high = 1. - 2.*(1. - base)*(1. - blend);
    vec3 selector = step(vec3(0.5), base);
    return mix(low, high, selector);
}
vec3 screen(vec3 base, vec3 blend){
    return 1. - 2.*(1. - base)*(1. - blend);
}

void main() {
    vec4 src = texture2D(texture, v_texCoord);

    if (src.a == 0.0) {
        gl_FragColor = src * v_color;
        return;
    }

    vec2 screenUV = gl_FragCoord.xy / viewportSize;

	//calc gradient pos in view pos
    vec2 viewPos = viewRect.xy;
    vec2 viewBr = viewRect.xy + viewRect.zw;
    vec2 worldPos = mix(viewPos, viewBr, screenUV);

	vec2 gPos = gradientRect.xy; 
    vec2 gSize = gradientRect.zw;
    vec2 gUV = (worldPos - gPos) / gSize;

	//clamp gradient coord if view is outside gradient rect 
    if (clampGradient && (gUV.x <0. || gUV.x > 1. || gUV.y<0. || gUV.y>1.)) {
		gl_FragColor = src * v_color;
        return;
    } else {
        gUV = clamp(gUV, 0.0, 1.0);
    }

	//calculate and apply gradient
    vec4 top = mix(colors[0], colors[1], gUV.x);     
    vec4 bot = mix(colors[3], colors[2], gUV.x);     
    vec4 grad = mix(top, bot, gUV.y);                

    float k = clamp(grad.a, 0.0, 1.0);

	vec3 tinted;
	if(tintMode == 0){tinted = overlay(src.rgb, grad.rgb);}
	else if(tintMode == 1){tinted = screen(src.rgb, grad.rgb);}
	else if(tintMode == 2){tinted = grad.rgb;}
    vec3 res = mix(src.rgb, tinted, k);

    gl_FragColor = vec4(res, src.a) * v_color;
}