#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

#define resolution vec2(480, 270)    
#define bloomIntensity 1.
#define sigma 1.
#define bloomRandomVariation 0.3 //between 0-1, makes bloom randomly less intense. Higher value means lower "valleys"

uniform sampler2D texture;
uniform vec3 lightColor;

// Gaussian weight function: higher sigma = wider blur
float gaussianWeight(float x, float y) {
    return exp(-(x * x + y * y) / (2.0 * sigma * sigma));
}

// A simple random function for noise
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main() {
    
    // Sample the original scene color.
    vec3 sceneColor = texture2D(texture, v_texCoord).rgb;
    
    // Optionally compute a brightness mask for the current pixel.
    vec3 mask = (distance(sceneColor, lightColor) < 0.01) ? sceneColor : vec3(0.0);
    
    // Accumulate a Gaussian-blurred bloom from a 5x5 kernel.
    vec3 bloom = vec3(0.0);
    float totalWeight = 0.0;
    
    // Loop over a kernel of offsets from -2 to +2 in both directions.
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            // Calculate the offset in normalized coordinates.
            vec2 offset = vec2(float(i), float(j)) / resolution;
            
            // Sample the scene at the offset.
            vec3 sampleColor = texture2D(texture, v_texCoord + offset).rgb;

            // Compute its brightness and apply the threshold to get the sample mask.
            vec3 sampleMask = (distance(sampleColor, lightColor) < 0.01) ? sampleColor : vec3(0.0);
            
            // Compute the weight for this sample using the Gaussian function.
            float weight = gaussianWeight(float(i), float(j));
            
            // Accumulate the weighted sample.
            bloom += sampleMask * weight;
            totalWeight += weight;
        }
    }
    
    // Normalize the bloom result.
    bloom /= totalWeight;

	//add random noise to bloom instensity
	float noise = random(v_texCoord * resolution);
    bloom *= 1 - bloomRandomVariation * noise;
    
    // Composite the bloom effect onto the original scene.
    gl_FragColor = vec4(sceneColor + bloom*(1.0 - sceneColor)*bloomIntensity, 1.0);
}