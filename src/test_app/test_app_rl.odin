package test_app

// import "core:fmt"
// import "core:time"
// import rl "vendor:raylib"

// FRAMERATE_TARGET :: 60
// NATIVE_WIDTH :: 480
// NATIVE_HEIGHT :: 270
// WINDOW_SCALE :: 2

// init :: proc(){
// 	rl.InitWindow(NATIVE_WIDTH, NATIVE_HEIGHT, "RL TEST")
// }
// main_rl :: proc() {

// 	init()
// 	rl.SetTargetFPS(FRAMERATE_TARGET)
//     when #config(ON_SWITCH, false){
// 		texture_path :cstring= "Contents:/swordsmanIdle.png"
// 	}
// 	else {
// 		texture_path :cstring= "D:/Project code/__Maintained Projects and Libraries/ODIN/massimodin/build/TexturePacking/default/swordsmanIdle/0000_540_47x48.png"
// 	}
// 	player_tex := rl.LoadTexture(texture_path)

//     player_pos := rl.Vector2{100, 100}
//     move_speed : f32 = 2

// 	shader := rl.LoadShaderFromMemory(vertex_source, fragment_source)

//     for (!rl.WindowShouldClose()){
        
//         move_x := f32(i8(rl.IsKeyDown(.RIGHT)) - i8(rl.IsKeyDown(.LEFT)))
//         move_y := f32(i8(rl.IsKeyDown(.DOWN)) - i8(rl.IsKeyDown(.UP)))

//         player_pos.x += move_x * move_speed
//         player_pos.y += move_y * move_speed

// 		fmt.println(player_pos, move_x, move_y)
// 		rl.BeginDrawing()
		

// 		rl.ClearBackground(rl.SKYBLUE)
// 		rl.BeginShaderMode(shader)
// 		rl.DrawTexture(player_tex, i32(player_pos.x), i32(player_pos.y), rl.RAYWHITE)
// 		rl.EndShaderMode()
//         rl.EndDrawing()
//     }

//     fmt.println("QUITTING")
// }



// vertex_source :cstring= `
// #version 330

// // Input vertex attributes
// in vec3 vertexPosition;
// in vec2 vertexTexCoord;
// in vec4 vertexColor;

// // Output vertex attributes (to fragment shader)
// out vec2 fragTexCoord;
// out vec4 fragColor;

// // NOTE: Add here your custom variables

// // Uniforms
// uniform mat4 mvp;

// void main()
// {
//     // Send vertex attributes to fragment shader
//     fragTexCoord = vertexTexCoord;
//     fragColor = vertexColor;

//     // Calculate final vertex position
//     gl_Position = mvp*vec4(vertexPosition, 1.0);
// }
// `

// fragment_source :cstring= `
// #version 330

// // Input vertex attributes (from vertex shader)
// in vec2 fragTexCoord;
// in vec4 fragColor;

// // Output fragment color
// out vec4 finalColor;

// // NOTE: Add here your custom variables

// // Uniforms
// uniform sampler2D texture0;
// uniform vec4 colDiffuse;

// void main()
// {
//     // Texel color fetching from texture sampler
//     vec4 texelColor = texture(texture0, fragTexCoord);

//     // NOTE: Implement here your fragment shader code

//     // Tint the texture red
//     finalColor = texelColor * vec4(1.0, 0.0, 0.0, 1.0);
// }
// `