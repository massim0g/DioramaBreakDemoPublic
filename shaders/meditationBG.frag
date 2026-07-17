#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

// Animation / control
uniform float time;      // seconds (or any time base)
uniform float strength;  // 0..1
uniform float scale;     // noise frequency scale (e.g. 2.0..6.0)

// ----- 3D Perlin (value-compatible) -----
float fade(float t) { return t*t*t*(t*(t*6.0-15.0)+10.0); }

float hash(float n) { return fract(sin(n)*43758.5453123); }
float hash(vec3 p) {
    // Simple lattice hash
    return fract(43758.5453 * sin(dot(p, vec3(127.1, 311.7, 74.7))));
}

vec3 grad3(float h) {
    int i = int(mod(floor(h * 12.0), 12.0));
    if (i == 0) return vec3( 1, 1, 0);
    if (i == 1) return vec3(-1, 1, 0);
    if (i == 2) return vec3( 1,-1, 0);
    if (i == 3) return vec3(-1,-1, 0);
    if (i == 4) return vec3( 1, 0, 1);
    if (i == 5) return vec3(-1, 0, 1);
    if (i == 6) return vec3( 1, 0,-1);
    if (i == 7) return vec3(-1, 0,-1);
    if (i == 8) return vec3( 0, 1, 1);
    if (i == 9) return vec3( 0,-1, 1);
    if (i == 10) return vec3( 0, 1,-1);
    return vec3( 0,-1,-1);
}

float perlin(vec3 p) {
    vec3 pi = floor(p);
    vec3 pf = p - pi;

    vec3 f = vec3(fade(pf.x), fade(pf.y), fade(pf.z));

    // Corner hashes → gradients
    float n000 = hash(pi + vec3(0.0,0.0,0.0));
    float n100 = hash(pi + vec3(1.0,0.0,0.0));
    float n010 = hash(pi + vec3(0.0,1.0,0.0));
    float n110 = hash(pi + vec3(1.0,1.0,0.0));
    float n001 = hash(pi + vec3(0.0,0.0,1.0));
    float n101 = hash(pi + vec3(1.0,0.0,1.0));
    float n011 = hash(pi + vec3(0.0,1.0,1.0));
    float n111 = hash(pi + vec3(1.0,1.0,1.0));

    vec3 g000 = grad3(n000), g100 = grad3(n100);
    vec3 g010 = grad3(n010), g110 = grad3(n110);
    vec3 g001 = grad3(n001), g101 = grad3(n101);
    vec3 g011 = grad3(n011), g111 = grad3(n111);

    float d000 = dot(g000, pf - vec3(0,0,0));
    float d100 = dot(g100, pf - vec3(1,0,0));
    float d010 = dot(g010, pf - vec3(0,1,0));
    float d110 = dot(g110, pf - vec3(1,1,0));
    float d001 = dot(g001, pf - vec3(0,0,1));
    float d101 = dot(g101, pf - vec3(1,0,1));
    float d011 = dot(g011, pf - vec3(0,1,1));
    float d111 = dot(g111, pf - vec3(1,1,1));

    float x00 = mix(d000, d100, f.x);
    float x10 = mix(d010, d110, f.x);
    float x01 = mix(d001, d101, f.x);
    float x11 = mix(d011, d111, f.x);

    float y0 = mix(x00, x10, f.y);
    float y1 = mix(x01, x11, f.y);

    // Range roughly [-1,1]
    return mix(y0, y1, f.z);
}

// Simple fBm for richer structure
float fbm(vec3 p) {
    float a = 0.5;
    float sum = 0.0;
    float norm = 0.0;
    for (int i = 0; i < 4; ++i) {
        sum += a * perlin(p);
        norm += a;
        p *= 2.0;
        a *= 0.5;
    }
    return sum / norm * 0.5 + 0.5; // map to [0,1]
}

void main()
{	
	float s = clamp(strength, 0.0, 1.0);

    // Sample a moving 2D slice through 3D noise
    float freq = max(scale, 0.0001);
    vec2 uv = v_texCoord * freq;
    float z = time * 0.003; // slice speed
    float n = fbm(vec3(uv, z)); // 0..1

    vec3 midTone = vec3(70./255., 80./255., 87./255.);
    vec3 white = vec3(247./255., 242./255., 216./255.);
    
	float a = clamp(s * 2.0, 0.0, 1.0);        // 0..0.5 phase (visibility up to purple)
    float b = clamp((s - 0.5) * 2.0, 0.0, 1.0);// 0.5..1 phase (fade tips to white)

    float i0 = 0.5 * a * n;              // 0..~0.5
    float i = mix(i0, 1.0, b * n);        // move tips along ramp to white
	i = mix(i, 1.0, b);

	vec3 color;
    
    if (i < 0.5) {
        float k = i * 2.0;          // 0..1 : black -> purple
        color= mix(vec3(0.0), midTone, k);
    } else {
        float k = (i - 0.5) * 2.0;  // 0..1 : purple -> white
        color= mix(midTone, white, k);
    }

	float roundStep = mix(0.,0.07,s);
	color = round(color/roundStep)*roundStep;

	vec4 inCol = texture2D(texture, v_texCoord);
    gl_FragColor = vec4(color, v_color.a);
}
