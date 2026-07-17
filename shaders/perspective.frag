#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform mat3 transform;
uniform vec2 screenSize;

void main()
{
    vec3 screen_coord = vec3(v_texCoord * screenSize, 1.0);
    vec3 unit_coord = transform * screen_coord;
    unit_coord /= unit_coord.z;
    vec2 uv = unit_coord.xy;

	
	
    // Optionally discard fragments outside the unit square.
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0){
        discard;
    }

    vec4 texColor = texture2D(texture, uv);
	if(texColor == vec4(1.,1.,1.,0.)){
		uv = round(uv*screenSize)/screenSize;
		texColor = texture2D(texture, uv);
		//texColor = vec4(0.,0.,1.,1.);
	}
    gl_FragColor = texColor * v_color;
}
