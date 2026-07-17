package massimodin //@nested-tags:engine/visuals

import "../sdl2"

MAX_PARTICLE_TYPES :: 63
ParticlesSystem :: struct{
	_types_array:[MAX_PARTICLE_TYPES+1]ParticleType,
	_types_count:int,
	_types_map:map[^Sprite][dynamic]^ParticleType,
	_groups:map[f32]ParticleGroup
}
particles:^ParticlesSystem

_particles_system_init :: proc(){
	particles = new(ParticlesSystem, os_allocator)

	init(&particles._types_map, os_allocator)
	init(&particles._groups, os_allocator)
}

Particle :: struct{ //todo: could use smaller types for fields as an optimization if needed
	type:^ParticleType,
	sprite:^Sprite,
	frameInd:int,
	animProgress:f32,
	age:int,
	lifetime:int,
	pos:Vec2,
	speed:f32,
	dir:Vec2,
	scale:Vec2,
	angle:f32
}
ParticleType :: struct{
	//update info
	sprites:[4]^Sprite, //selects a random sprite in the array when emitting. All sprites are assumed to be of the same duration.
	spriteDuration:f32,
	animSpeed:f32,
	scaleCurves:[2]^Curve,
	angleChange:f32,
	dirChange:f32,
	dirChangeMatrix:matrix[2,2]f32,
	colors:[3]Color,
	colorCurve:^Curve,
	alphaCurve:^Curve,
	
	//spawning info
	minLifetime:int,
	maxLifetime:int,
	minSpeed:f32,
	maxSpeed:f32,
	acceleration:union{f32,Vec2,^Curve},
	minScale:f32,
	maxScale:f32,
	angle:f32,
	angleSpread:f32,
	dir:f32,
	dirSpread:f32,
	randomFrame:bool,
	angleMatchesDir:bool,
	spriteCount:u8 //essentially a fixed-capacity dynamic array, but we use a simple array and have len here so that particle types are simply comparable
}

ParticleGroup :: struct{
	particles:[dynamic]Particle
}

//Will only allocate a new particle type if the aguments do not match any that exist
particle_type :: proc(
	sprites:union{^Sprite,[]^Sprite,[4]^Sprite},
	minLifetime:int,
	maxLifetime:int=0,
	minSpeed:f32=0,
	maxSpeed:f32=0,
	acceleration:union{f32,Vec2,^Curve}=f32(0),

	animSpeed:f32=1,
	randomFrame:bool=true,
	minScale:f32=1,
	maxScale:f32=1,
	scaleCurves:[2]^Curve=nil,
	colors:[3]Color={COLOR_WHITE, COLOR_WHITE, COLOR_WHITE},
	alphaCurve:^Curve=nil,
	angle:f32=0,
	angleSpread:f32=360,
	angleChange:f32=0,
	dir:f32=0,
	dirSpread:f32=360,
	dirChange:f32=0,
	angleMatchesDir:bool=false
) -> ^ParticleType{
	
	pt := ParticleType{}

	keySprite:^Sprite
	switch spr in sprites{
		case ^Sprite: 
			keySprite = spr
			pt.sprites[pt.spriteCount] = spr
			pt.spriteCount += 1
		case []^Sprite:
			keySprite = spr[0]
			for sprite in spr{
				pt.sprites[pt.spriteCount] = sprite
				pt.spriteCount += 1
			}
		case [4]^Sprite:
			keySprite = spr[0]
			pt.sprites = spr
	}
	
	pt.spriteDuration = sprite_duration_f(keySprite, .milliseconds)
	pt.minLifetime = minLifetime
	pt.maxLifetime = max(maxLifetime, minLifetime) 
	pt.minSpeed = minSpeed 
	pt.maxSpeed = max(minSpeed, maxSpeed) 

	pt.animSpeed = animSpeed 
	pt.randomFrame = randomFrame

	pt.acceleration = acceleration

	pt.minScale = minScale
	pt.maxScale = max(minScale, maxScale)
	pt.scaleCurves = scaleCurves

	pt.colors = colors
	pt.alphaCurve = alphaCurve

	pt.angle = angle
	pt.angleSpread = angleSpread
	pt.dir = dir
	pt.dirSpread = dirSpread
	pt.dirChange = dirChange
	pt.dirChangeMatrix = {
		cos(dirChange), sin(dirChange),
		-sin(dirChange), cos(dirChange)
	}
	pt.angleMatchesDir = angleMatchesDir 
	pt.angleChange = angleMatchesDir ? dirChange : angleChange

	out := &particles._types_array[particles._types_count]
	if typesArr, ok := &particles._types_map[keySprite]; ok{
		for ptr in typesArr{
			if ptr^ == pt do return ptr
		}
		append(typesArr, out)
	}
	else{
		particles._types_map[keySprite] = make([dynamic]^ParticleType, os_allocator)
		append(&particles._types_map[keySprite], out)
	}

	out^ = pt
	particles._types_count += 1
	assert(particles._types_count <= MAX_PARTICLE_TYPES, "Created too many particle types!")

	return out
}

//creates a copy of a particle type with a different sprite (the way this works now is a bit silly and has to be redone)
particle_type_clone_sprite :: proc(pt:^ParticleType, newSprite:^Sprite) -> ^ParticleType{
	if newSprite == pt.sprites[0] do return pt

	return particle_type(newSprite, 
		pt.minLifetime, pt.maxLifetime, 
		pt.minSpeed, pt.maxSpeed, pt.acceleration,
		pt.animSpeed, pt.randomFrame, 
		pt.minScale, pt.maxScale, pt.scaleCurves,
		pt.colors, pt.alphaCurve, 
		pt.angle, pt.angleSpread, pt.angleChange,
		pt.dir, pt.dirSpread, pt.dirChange, pt.angleMatchesDir
	)
}

particle_type_clone_type :: proc(pt:ParticleType) -> ^ParticleType{
	return particle_type(pt.sprites, 
		pt.minLifetime, pt.maxLifetime, 
		pt.minSpeed, pt.maxSpeed, pt.acceleration,
		pt.animSpeed, pt.randomFrame, 
		pt.minScale, pt.maxScale, pt.scaleCurves,
		pt.colors, pt.alphaCurve, 
		pt.angle, pt.angleSpread, pt.angleChange,
		pt.dir, pt.dirSpread, pt.dirChange, pt.angleMatchesDir
	)
}
particle_type_clone :: proc{particle_type_clone_sprite, particle_type_clone_type}

//use depth=-INF to draw above the UI
particles_emit :: proc(pt:^ParticleType, count:int, depth:f32, region:Rect){
	if !(depth in particles._groups){
		particles._groups[depth] = ParticleGroup{
			make([dynamic]Particle, os_allocator)
		}
	}
	group := &particles._groups[depth]
	parts := &group.particles

	startInd := len(parts)
	newLen := startInd + count
	resize(parts, newLen)
	
	for i in startInd..<newLen{

		dirAngle := random_range(pt.dir-pt.dirSpread/2, pt.dir+pt.dirSpread/2)
		dir := vec2_offset(dirAngle)

		sprite := pt.sprites[0]
		if pt.spriteCount > 1 do sprite = pt.sprites[random(int(pt.spriteCount))]

		frameInd:int
		animProgress:f32
		if(pt.randomFrame){
			frameInd = random(len(sprite.frames))
			animProgress = sprite_frame_time_get(sprite, frameInd, .milliseconds)
		}

		parts[i] = Particle{
			pt,
			sprite,
			frameInd,
			animProgress,
			-1,
			random_range(pt.minLifetime, pt.maxLifetime),
			{
				region.x + random(region.size.x),
				region.y + random(region.size.y)
			},
			random_range(pt.minSpeed, pt.maxSpeed),
			dir,
			random_range(pt.minScale, pt.maxScale),
			pt.angleMatchesDir ? dirAngle : random_range(pt.angle-pt.angleSpread/2, pt.angle+pt.angleSpread/2)
		}
	}
}

//emits particles at the edge of a circular region. position is determined by particle direction
particles_emit_circle :: proc(pt:^ParticleType, count:int, depth:f32, region:Circle, wobble:f32=0, moveInward:bool=false){
	if !(depth in particles._groups){
		particles._groups[depth] = ParticleGroup{
			make([dynamic]Particle, os_allocator)
		}
	}
	group := &particles._groups[depth]
	parts := &group.particles

	startInd := len(parts)
	newLen := startInd + count
	resize(parts, newLen)
	
	for i in startInd..<newLen{

		dirAngle := random_range(pt.dir-pt.dirSpread/2, pt.dir+pt.dirSpread/2)
		dir := vec2_offset(dirAngle)
		if moveInward do dir = -dir
		pos := vec2_offset(dirAngle, random_range(region.radius-wobble/2, region.radius+wobble/2), region.pos)

		sprite := pt.sprites[0]
		if pt.spriteCount > 1 do sprite = pt.sprites[random(int(pt.spriteCount))]

		frameInd:int
		animProgress:f32
		if(pt.randomFrame){
			frameInd = random(len(sprite.frames))
			animProgress = sprite_frame_time_get(sprite, frameInd, .milliseconds)
		}

		parts[i] = Particle{
			pt,
			sprite,
			frameInd,
			animProgress,
			-1,
			random_range(pt.minLifetime, pt.maxLifetime),
			pos,
			random_range(pt.minSpeed, pt.maxSpeed),
			dir,
			random_range(pt.minScale, pt.maxScale),
			pt.angleMatchesDir ? dirAngle : random_range(pt.angle-pt.angleSpread/2, pt.angle+pt.angleSpread/2)
		}
	}
}

particles_draw :: proc(parts:[]Particle){
	//trace(format("Particles Draw: %s", parts[0].sprite.name))
	camPosF := camera_pos()
	for &p in parts{
		//Optimized draw_sprite
		spr := p.sprite
		prog := f32(p.age)/f32(p.lifetime)

		blend:Blend 
		if(prog <= 0.5) do blend.rgb = color_lerp(p.type.colors[0], p.type.colors[1], prog*2)
		else do blend.rgb = color_lerp(p.type.colors[1], p.type.colors[2], (prog-0.5)*2)
		blend.a = p.type.alphaCurve == nil ? 255 : u8(curve_eval(p.type.alphaCurve, prog)*255)

		frame := spr.frames[p.frameInd]

		scale:= Vec2{
			p.type.scaleCurves.x == nil ? p.scale.x : p.scale.x*curve_eval(p.type.scaleCurves.x, prog), 
			p.type.scaleCurves.y == nil ? p.scale.y : p.scale.y*curve_eval(p.type.scaleCurves.y, prog)
		}
		size := Vec2{f32(frame.texturePagePos.w), f32(frame.texturePagePos.h)}
		newSize := size*scale
		sizeDelta := newSize - size

		origin := Vec2{f32(spr.origin.x - frame.trimOffset.x), f32(spr.origin.y - frame.trimOffset.y)}
		origin.x += size.x - origin.x*2 - 1
		origin.y += size.y - origin.y*2 - 1

		destRect := sdl2.FRect{
			p.pos.x - origin.x - origin.x/size.x*sizeDelta.x - camPosF.x,
			p.pos.y - origin.y - origin.y/size.y*sizeDelta.y - camPosF.y,
			newSize.x,
			newSize.y
		}

		pivot := sdl2.FPoint{origin.x*scale.x, origin.y*scale.y}
		
		sdl2.SetTextureColorMod(frame.texturePage, blend.r, blend.g, blend.b)
		sdl2.SetTextureAlphaMod(frame.texturePage, blend.a)
		sdl2.SetTextureBlendMode(frame.texturePage, .BLEND)
		sdl2.RenderCopyExF(display._renderer, frame.texturePage, &frame.texturePagePos, &destRect, f64(p.angle), &pivot, sdl2.RendererFlip.NONE)
	}
}

particles_clear_all :: proc(){
	for _,group in particles._groups{
		delete(group.particles)
	}
	clear(&particles._groups)
}

_particles_system_update :: proc(){
	toDelete := make([dynamic]f32, context.temp_allocator)
	for key, &group in particles._groups{
		if combat.time_stop_mode != .disabled && key != -INF do continue
		parts := &group.particles
		#reverse for &p, i in parts{ //hot!
			p.age += 1
			if(p.age >= p.lifetime){
				unordered_remove(parts, i)
				continue
			}

			p.animProgress += time.target_delta*p.type.animSpeed
			dur := p.type.spriteDuration
			if(p.animProgress >= dur){
				p.animProgress -= dur
				p.frameInd = 0
			}
			else if(p.frameInd < len(p.sprite.frames)-1 && p.animProgress >= f32(p.sprite.frames[p.frameInd+1].framePosition)){
				p.frameInd += 1
			}

			p.dir = p.dir*p.type.dirChangeMatrix

			switch acc in p.type.acceleration{
				case f32: 
					p.speed += acc
					p.pos += p.speed*p.dir
				case Vec2: 
					spd := p.dir*p.speed + acc
					p.pos += spd
					p.speed = vec2_mag_get(spd)
					p.dir = spd/p.speed
				case ^Curve:
					p.pos += p.dir*p.speed*curve_eval(acc, f32(p.age)/f32(p.lifetime))
			}
			
			
			p.angle += p.type.angleChange
		}

		if(len(group.particles) == 0){
			delete(group.particles)
			append(&toDelete, key)
		}
	}

	for key in toDelete{
		delete_key(&particles._groups, key)
	}
}