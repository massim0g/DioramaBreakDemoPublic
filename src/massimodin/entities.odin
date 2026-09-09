package massimodin //@nested-tags:engine/entities

import "core:mem"
import "base:intrinsics"
import "core:container/priority_queue"
import slices "core:slice"
import "core:reflect"

EntitySystem :: struct{
	created:int, //total entities created over the entire program's runtime, determines an entity's ID. 
	_list:[dynamic]Entity,
	_id_map:map[EntityID]^Entity,
	_just_made_buffer:[]Entity,
	_just_added_buffer:[dynamic]JustAddedCoRef,
	_destroy_list:[dynamic]^Entity,
	_persistent_list:[dynamic]EntityID,
	component_type_event_register:[Event][dynamic]CoID, //keeps track of what active component types an event needs to call when processed. Higher priority events get called first.
	
	active_component_types:[CoID]bool,
	component_type_metadata:[CoID]ComponentTypeMetadata,
	prefabs:[dynamic]EntityPrefab,
	context_component:^ComponentBase,

	_component_names:[]string,

	_component_arrays:ComponentArrays,

}
entities:^EntitySystem

_entity_system_init :: proc(){
	entities = new(EntitySystem)

	init(&entities._list)
	init(&entities._id_map)
	init(&entities._just_added_buffer)
	init(&entities._destroy_list)
	init(&entities._persistent_list)
	for e in Event{
		init(&entities.component_type_event_register[e])
	}

	init(&entities.prefabs, assets.allocator)

	reserve(&entities._list, ENTITIES_CAP)
	entities._just_made_buffer = entities._list[0:][:0]
	entities._component_names = reflect.enum_field_names(CoID)

	_components_metadata_init()
}

//ENTITY
Entity :: struct{
    id:EntityID,
	persistent:bool, //DO NOT SET DIRECTLY
    requiredComponentCount:int,
    uniqueComponentCount:int,
    components: [COMPONENTS_MAX_PER_ENTITY*2]^ComponentBase,
	componentRefRefs: [COMPONENTS_MAX_PER_ENTITY*2][dynamic]CoRefRef, //for every component, store a list references to that component from within the component's entity. These "ref refs" are not pointers, but rather an index + memory offset that can be used to obtain a pointer to a CoRef if used in combination with an address to the entity
	renderComponentIndices:[dynamic; COMPONENTS_MAX_PER_ENTITY*2]u8
}

EntityPrefab :: struct{
	lastComponent:CoID,
	previewSprite:^Sprite,
	name:string,
	onCreate:rawptr,
	onCreateWrapper:proc(co:^ComponentBase, p:rawptr)
}

EntityID :: distinct int

ENTITIES_CAP :: 2048 //Maximum number of entities that can be active at once. Keep low to reduce memory usage
COMPONENT_EDITABLE_STRING_MAX_SIZE :: 64 //maximum size of component strings editable in the inspector, in bytes. Editable strings always assume the component has ownership of them.


//COMPONENTS
ComponentBase :: struct{
    entity:^Entity,
    myEntityIndex:int, //index of the component pointer within the entity's component array
	disabledEvents:bit_set[Event],
	coID:CoID,
	unique:bool,
	initialized:bool,
	editableFieldsVisible:bool //for stage editor. Useful if you want to override the normal behavior in the .editing event
}

RenderComponentBase :: struct{
    using baseBase:ComponentBase,
    depth:f32,
    visible:bool
}

//Wraps a pointer that's specifically used by components to store a reference to another component on the same entity and is kept up-to-date by the entity system
CoRef :: struct($T:typeid){ 
	using _ptr:^T
}

//Used to keep track of component refs
CoRefRef :: struct{ 
	refIndex:int, //index to the component which has this ref
	refOffset:int //memory offset used to locate the CoRef's exact memory address
}

JustAddedCoRef :: struct{
	entity:^Entity,
	ind:int
}

//Used as a stable reference to a single component on any entity.
CoRefEx :: struct($T:typeid){ 
	entityID:EntityID,
	index:int
}

CoRefExGeneric :: struct{
	entityID:EntityID,
	index:int
}

ComponentTypeMetadata :: struct{
	name:string,
    EventPriorities:[Event]i8,
	editableFields:[]reflect.Struct_Field,
    isRenderComponent:bool,
	type:typeid,
    process_array:proc(event:Event),
    process:proc(base:^ComponentBase, event:Event, overrideDisabled:=false),
    append_to_array:proc(bufferedComponent:^ComponentBase)->^ComponentBase,
	remove_from_array:proc(index:int),
	move_to_heap:proc(index:int) -> ^ComponentBase,
	get_component_index:proc(component:^ComponentBase) -> int,
	get_array_pointer:proc()->^RawArray,
	clear_array:proc()
}

COMPONENTS_MAX_PER_ENTITY :: 16 //NOTE: The actual number of max components is *double* this value, since this is used for both required and unique components

//Events
Event :: enum{
    init,
	stageStart,
	loaded, //called right after a component is loaded from serialized data, such as on stage start
	loading, //called *while* a component is being loaded from serialized data. Use stage.loadingComponentData to access the serialized data. Called after the current component has been loaded normally, but other components on the entity are not guaranteed to have been loaded yet.
	saving, //similarly, called while a component is being serialized. Use stage.savingComponentsBuilder to access the json string buffer.
	editing, //called while the inspector gui code is being called, allows you to add more debug gui widgets when inspecting a component
	justMade, //called right after a component is appended to its respective array, usually at the very end of the frame it was created. Useful for various stuff. Note that anytime during stage start, this will be called basically as soon as the entity is created.
	codeReload, //called after code is hot-reloaded, debug only
	assetReload, //called after assets are hot-reloaded, debug only
    destroy,
    clean,
    updateBegin,
    update,
    updateEnd,
	updateEditor, //normal update events are not called in the stage editor, so use this if you want stuff to happen in that context
	bulkUpdate, //special event used outside of the normal event_process proc. Can be used to efficiently work on the whole array of components, rather than one at a time. Better for performance but loses some convenience.
	preDraw,
    draw,
	drawEditor, //`draw` is also called in-editor, so this event is for additional draws
	editorUndo,
	editorRedo
}

RENDER_EVENTS :: [?]Event{.draw, .drawEditor} //in order
EVENT_NIL_PRIORITY :i8: -127
EVENT_NIL_ARRAY :: [Event]i8{
    .init = EVENT_NIL_PRIORITY,
    .stageStart = EVENT_NIL_PRIORITY,
	.loaded = EVENT_NIL_PRIORITY,
	.loading = EVENT_NIL_PRIORITY,
	.saving = EVENT_NIL_PRIORITY,
	.editing = EVENT_NIL_PRIORITY,
	.justMade = EVENT_NIL_PRIORITY,
	.codeReload = EVENT_NIL_PRIORITY,
	.assetReload = EVENT_NIL_PRIORITY,
    .destroy = EVENT_NIL_PRIORITY,
    .clean = EVENT_NIL_PRIORITY,
    .updateBegin = EVENT_NIL_PRIORITY,
    .update = EVENT_NIL_PRIORITY,
    .updateEnd = EVENT_NIL_PRIORITY,
	.updateEditor = EVENT_NIL_PRIORITY,
	.bulkUpdate = EVENT_NIL_PRIORITY,
	.preDraw = EVENT_NIL_PRIORITY,
    .draw = EVENT_NIL_PRIORITY,
    .drawEditor = EVENT_NIL_PRIORITY,
	.editorUndo = EVENT_NIL_PRIORITY,
	.editorRedo = EVENT_NIL_PRIORITY,
}

//Create an entity with no components. Returns a temporary pointer to that entity as well.
entity_make_empty :: proc() -> (EntityID, ^Entity){
	entities.created += 1 //increment by 1 before assigning ID because 0 is the nil value
    out := EntityID(entities.created)
    newInd := len(entities._list)

	assert(newInd < ENTITIES_CAP, "Too many entities created!")

    append_elem(&entities._list, Entity{})

    newEntityPtr := &entities._list[newInd]
    newEntityPtr.id = out;
    entities._id_map[out] = newEntityPtr

	justCreatedCount := len(entities._just_made_buffer)
	entities._just_made_buffer = entities._list[newInd-justCreatedCount:][:justCreatedCount+1]

	return out, newEntityPtr
}

entity_make_coids :: proc(coIDs: ..CoID) -> ^ComponentBase{
	_, newEntityPtr := entity_make_empty()

	lastPtr:^ComponentBase
	for id in coIDs{
		lastPtr = component_add_using_coid(newEntityPtr, id)
	}

    return lastPtr
}
entity_make_constant :: proc($finalComponent:typeid) -> ^finalComponent{
	ptr := entity_make_coids(coid_of(finalComponent))
	return cast(^finalComponent)ptr
}
//Create an entity with the specified component(s) (either multiple coids or a constant component type). Specify dependencies in the component's create event. Use entity_make_empty to make an entity with no components.
entity_make :: proc{entity_make_coids, entity_make_constant}

entity_destroy_type :: proc($T:typeid){
	ents := coall(T)
	for &ent in ents{
		entity_destroy(&ent)
	}
}
entity_destroy_ptr :: proc(entity:^Entity){
	if(entity == nil || contains(entities._destroy_list, entity)) do return
	entity_persistent_set(entity, false) //prevents certain errors if attempting to load a new stage (clearing all entities) before destroy list is handled at the end of the frame
	entityIntAddress := uintptr(entity)
	broke := false
	for i:=len(entities._destroy_list)-1; i>=0; i-=1{
		if(entityIntAddress < uintptr(entities._destroy_list[i])){
			inject_at(&entities._destroy_list, i+1, entity)
			broke = true
			break;
		}
	}
	if(!broke) do inject_at(&entities._destroy_list, 0, entity)

	for i in 0..<entity.requiredComponentCount{
		entities.component_type_metadata[entity.components[i].coID].process(entity.components[i], .destroy)
	}	
	for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
		entities.component_type_metadata[entity.components[i].coID].process(entity.components[i], .destroy)
	}
	
}
entity_destroy_id :: #force_inline proc(id:EntityID){
	entity_destroy_ptr(entity_get(id))
}
entity_destroy_component_base :: #force_inline proc(co:^ComponentBase){
	if co == nil do return
	entity_destroy_ptr(co.entity)
}
entity_destroy :: proc{entity_destroy_ptr, entity_destroy_id, entity_destroy_component_base, entity_destroy_type}

entity_get :: #force_inline proc(id:EntityID) -> ^Entity{
	return entities._id_map[id]
}

entity_index_get :: #force_inline proc "contextless" (entity:^Entity) -> int{
	return mem.ptr_sub(entity, &entities._list[0])
}

entity_just_made :: proc(entity:^Entity) -> bool{
	for i:=len(entities._just_made_buffer)-1; i>=0; i-=1{
		checkPtr, ok := slices.get_ptr(entities._just_made_buffer, i)
		if(checkPtr == entity) do return true
	}
	return false
}

entity_persistent_set :: proc(entity:^Entity, val:bool){
	index, found := slices.linear_search(entities._persistent_list[:], entity.id)
	
	if(val && !found) do append(&entities._persistent_list, entity.id)
	if(!val && found) do unordered_remove(&entities._persistent_list, index)
	entity.persistent = val
}

entity_render_components :: proc(entity:^Entity) -> []^RenderComponentBase{
	out := make([]^RenderComponentBase, len(entity.renderComponentIndices), context.temp_allocator)
	for ind, i in entity.renderComponentIndices{
		out[i] = cast(^RenderComponentBase)entity.components[ind]
	}
	return out
}

cowith :: proc(co:^ComponentBase){ //sets the context for "co" functions
	entities.context_component = co
}

//returns the context for "co" functions, cast to a specific known type
cocontext :: proc($T:typeid)->^T{
	return cast(^T)entities.context_component
}

component_get_using_pointer :: #force_inline proc(entity:^Entity, index:int, $T:typeid) -> ^T{
	return cast(^T)entity.components[index]
}
component_get_using_id :: #force_inline proc(id:EntityID, index:int, $T:typeid) -> ^T{
	return component_get_using_pointer(entity_get(id), index)
}
component_get_using_crx :: #force_inline proc(ref:CoRefEx($T)) -> ^T{
	entity := entity_get(ref.entityID)
	if(entity == nil) do return nil
	return component_get_using_pointer(entity, ref.index, T)
}
coget :: proc{component_get_using_pointer, component_get_using_id, component_get_using_crx}

crx_from_coref :: #force_inline proc "contextless" (component:CoRef($T)) -> CoRefEx(T){
	return crx_from_ptr(component._ptr)
}
crx_from_ptr :: #force_inline proc "contextless" (component:^$T) -> CoRefEx(T){
	base := cast(^ComponentBase)component
	return CoRefEx(T){base.entity.id, base.myEntityIndex}
}
crx :: proc{crx_from_coref, crx_from_ptr}

crx_generic :: proc(co:^ComponentBase) -> CoRefExGeneric{
	return CoRefExGeneric{co.entity.id, co.myEntityIndex}
}

component_find :: proc(entity:^Entity, $componentType:typeid) -> (component:^componentType, found:bool) #optional_ok{
	searchID := coid_of(componentType)
	for i in 0..<entity.requiredComponentCount{
		if(entity.components[i].coID == searchID) do return cast(^componentType)entity.components[i], true
	}
	for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
		if(entity.components[i].coID == searchID) do return cast(^componentType)entity.components[i], true
	}
	return nil, false
}
component_find_using_component :: proc(co:^ComponentBase, $componentType:typeid) -> (component:^componentType, found:bool) #optional_ok{
	return component_find(co.entity, componentType)
}
component_find_using_coref :: proc(co:CoRef($T), $componentType:typeid) -> (component:^componentType, found:bool) #optional_ok{
	return component_find(co.entity, componentType)
}
component_find_using_context :: #force_inline proc($componentType:typeid) -> (component:^componentType, found:bool) #optional_ok{
	return component_find(entities.context_component.entity, componentType)
}
component_find_using_id :: #force_inline proc(id:EntityID, $componentType:typeid) -> (component:^componentType, found:bool) #optional_ok{
	return component_find(entity_get(id), componentType)
}
component_find_using_meta_index :: proc($componentType:typeid, ind:int) -> (component:^componentType, found:bool) #optional_ok{
	arr := cast(^[dynamic]componentType)entities.component_type_metadata[coid_of(componentType)].get_array_pointer()
	if(len(arr) <= ind){
		if ind == 0{
			for &ent in entities._just_made_buffer{
				if co, ok := cofind(&ent, componentType); ok do return co, true
			}
			for ref in entities._just_added_buffer{
				co := ref.entity.components[ref.ind]
				if co.coID == coid_of(componentType) do return cast(^componentType)co, true
			}
		}
		return nil, false
	}
	return &arr[ind], true
}
cofind :: proc{component_find_using_context, component_find, component_find_using_id, component_find_using_meta_index, component_find_using_component, component_find_using_coref}

component_add_using_coid :: proc(entity:^Entity, coID:CoID, unique:=false, noInit:=false, uniqueIndex:=0) -> ^ComponentBase{
    //componentType := typeid_of(type_of(templateComponentPtr^))
    //attempt to retrieve existing required component
    if(!unique){
        for i in 0..<entity.requiredComponentCount{
			co := entity.components[i]
            if co.coID == coID{
				if(!noInit && !co.initialized){
					component_event_process(co, .init)
					co.initialized = true
				}
                return co
            }
        }
    }
    else if uniqueIndex>=0{
        for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			co := entity.components[i]
			checkInd := uniqueIndex
            if co.coID == coID{
				if checkInd == 0{
					if(!noInit && !co.initialized){
						component_event_process(co, .init)
						co.initialized = true
					}
					return co
				}
				else do checkInd -= 1
            }
        }
    }

    //get type id and metadata
    componentTypeMetadata := entities.component_type_metadata[coID]

	//activates component type if necessary
    _component_type_activate(coID)

    //instantiate and store component
    newComponentPtr := cast(^ComponentBase)new_typeid(componentTypeMetadata.type, context.temp_allocator)

    newComponentIndex:int
    if(!unique){
        newComponentIndex = entity.requiredComponentCount
        entity.requiredComponentCount += 1
        assert(entity.requiredComponentCount <= COMPONENTS_MAX_PER_ENTITY, "ERROR: Too many non-unique components added to entity!")
    }
    else{
        newComponentIndex = COMPONENTS_MAX_PER_ENTITY + entity.uniqueComponentCount
        entity.uniqueComponentCount += 1
        assert(entity.uniqueComponentCount <= COMPONENTS_MAX_PER_ENTITY, "ERROR: Too many unique components added to entity!")
    }

    entity.components[newComponentIndex] = newComponentPtr

    //initialize component
    newComponentPtr.myEntityIndex = newComponentIndex
    newComponentPtr.entity = entity
    newComponentPtr.coID = coID
	newComponentPtr.unique = unique
	newComponentPtr.editableFieldsVisible = true
    
    if(componentTypeMetadata.isRenderComponent){
		renderPtr := cast(^RenderComponentBase)newComponentPtr
        renderPtr.depth = 0
        renderPtr.visible = true
		append(&entity.renderComponentIndices, u8(newComponentIndex))
    }
	
	if(!entity_just_made(entity)) do append(&entities._just_added_buffer, JustAddedCoRef{entity, newComponentIndex})

    if(!noInit){
		componentTypeMetadata.process(newComponentPtr, .init)
		newComponentPtr.initialized = true
	}
	
    return newComponentPtr
}
component_add :: proc(entity:^Entity, $componentType:typeid, unique:=false, noInit:=false, uniqueIndex:=0) -> ^componentType{
	return cast(^componentType)component_add_using_coid(entity, coid_of(componentType), unique)
}
component_add_using_component :: proc(co:^ComponentBase, $componentType:typeid, unique:=false, noInit:=false, uniqueIndex:=0) -> ^componentType{
	return component_add(co.entity, componentType, unique, noInit, uniqueIndex)
}
component_add_using_context :: proc($componentType:typeid, unique:=false, noInit:=false, uniqueIndex:=0) -> ^componentType{
	return component_add(entities.context_component.entity, componentType, unique)
}
component_add_using_id :: proc(id:EntityID, $componentType:typeid, unique:=false, noInit:=false, uniqueIndex:=0)-> ^componentType{
	return component_add(eget(id), componentType, unique)
}
component_add_using_context_and_ref :: proc(ref:^CoRef($T), unique:=false, noInit:=false, uniqueIndex:=0){
	newComponentPtr := component_add_using_context(T, unique)
	
	//append the corefref
	coRef_init(ref, newComponentPtr, entities.context_component)
}
coadd :: proc{component_add_using_context, component_add, component_add_using_component, component_add_using_id, component_add_using_context_and_ref, component_add_using_coid}

//Gets a component's index in the backing array of that component type. Not guaranteed to be stable between frames if components of that type are created or destroyed. 
component_array_index :: proc(co:^ComponentBase)->int{
	return entities.component_type_metadata[co.coID].get_component_index(co)
}

//registers component type as active with the entity system (if it is not already)
_component_type_activate :: proc(coID:CoID){
	if(entities.active_component_types[coID]) do return //component type is already active
	
	entities.active_component_types[coID] = true

    //subscribe component type to events
	eventPriorities := &entities.component_type_metadata[coID].EventPriorities
	for e in Event{
		priority := eventPriorities[e]
		if(priority != EVENT_NIL_PRIORITY){
			register := &entities.component_type_event_register[e]
			broke := false
			for i:=len(register)-1; i>=0; i-=1{
				if(priority <= entities.component_type_metadata[register[i]].EventPriorities[e]){
					inject_at(register, i+1, coID)
					broke = true
					break;
				}
			}
			if(!broke) do inject_at(register, 0, coID)
		}
	}
}

coRef_init :: proc(ref:^CoRef($T), ptr:^T, refOwner:^ComponentBase){
	ref._ptr = ptr
	basePtr := cast(^ComponentBase)ptr
	crrs := &refOwner.entity.componentRefRefs[basePtr.myEntityIndex]
	if(raw_data(crrs^) == nil) do init(crrs)
	append(crrs, CoRefRef{
		refOwner.myEntityIndex,
		int(uintptr(ref)) - int(uintptr(refOwner))
	})
}

//Will not return components that were created/added this frame
coall :: proc($componentType:typeid) -> []componentType{
	metadata := entities.component_type_metadata[coid_of(componentType)]
	arr := cast(^[dynamic]componentType)metadata.get_array_pointer()
	return arr[:]
}

//Slower, and requires allocation, but will return pointers to all components of a type, including those created/added this frame.
//Can optionally sort by entity ID (ascending) to produce a consistent order.
coall_true :: proc($componentType:typeid, sortOutput:=false, allocator:=context.temp_allocator) -> []^componentType{
	coID := coid_of(componentType)
	metadata := entities.component_type_metadata[coID]
	arr := cast(^[dynamic]componentType)metadata.get_array_pointer()
	out := make([dynamic]^componentType, len(arr), allocator)
	for &c, i in arr{
		out[i] = &c
	}

	for &entity in entities._just_made_buffer{
		for i in 0..<entity.requiredComponentCount{
			component := entity.components[i]
			if component.coID == coID do append(&out, cast(^componentType)component) 
		}
		
		for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			component := entity.components[i]
			if component.coID == coID do append(&out, cast(^componentType)component) 
		}
	}

	for ref in entities._just_added_buffer{
		component := ref.entity.components[ref.ind]
		if component.coID == coID do append(&out, cast(^componentType)component) 
	}

	if sortOutput{
		sort_array(&out, proc(a,b:^componentType)->bool{
			return (cast(^ComponentBase)a).entity.id < (cast(^ComponentBase)b).entity.id
		})
	}
	shrink(&out)
	return out[:]
}

//Will not count components created this frame
cocount :: proc(coID:CoID) -> int{
	return entities.component_type_metadata[coID].get_array_pointer().len
}

//Slower, counts components created this frame.
//If called from a component init of the same type, that component *will* be counted
cocount_true :: proc(coID:CoID) -> int{
	out := entities.component_type_metadata[coID].get_array_pointer().len

	for &entity in entities._just_made_buffer{
		for i in 0..<entity.requiredComponentCount{
			component := entity.components[i]
			if component.coID == coID do out += 1
		}
		
		for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			component := entity.components[i]
			if component.coID == coID do out += 1
		}
	}

	for ref in entities._just_added_buffer{
		component := ref.entity.components[ref.ind]
		if component.coID == coID do out += 1
	}

	return out
}

coid_from_name :: proc(name:string) -> (coid:CoID, ok:bool){
	return reflect.enum_from_name(CoID, name)
}

entity_exists_from_id :: #force_inline proc(e:EntityID) -> bool{
	ptr := entities._id_map[e]
	return ptr != nil && !contains(entities._destroy_list, ptr)
}
entity_exists_from_crx :: #force_inline proc(ref:CoRefEx($T)) -> bool{
	return entity_exists_from_id(ref.entityID)
}
entity_exists_from_ptr :: #force_inline proc(ptr:^Entity) -> bool{
	return ptr != nil && ptr.id in entities._id_map && !contains(entities._destroy_list, ptr)
}
entity_exists_from_component_type :: #force_inline proc($componentType:typeid) -> bool{
	_,ok:=cofind(componentType,0)
	return ok
}
entity_exists :: proc{entity_exists_from_id, entity_exists_from_crx, entity_exists_from_ptr, entity_exists_from_component_type}



component_event_process_coref :: proc(component:CoRef($T), event:Event, overrideDisabled:=true){
	ptr := cast(^ComponentBase)component._ptr
	component_event_process_ptr(ptr, event, overrideDisabled)
}
component_event_process_ptr :: proc(component:^ComponentBase, event:Event, overrideDisabled:=true){
	entities.component_type_metadata[component.coID].process(component, event, overrideDisabled)
}
component_event_process :: proc{component_event_process_coref, component_event_process_ptr}

component_events_disable_coref :: proc(component:CoRef($T), events:bit_set[Event], disabled:=true){
	ptr := cast(^ComponentBase)component._ptr
	component_events_disable_ptr(ptr, events, disabled)
}
component_events_disable_ptr :: proc(component:^ComponentBase, events:bit_set[Event], disabled:=true){
	component.disabledEvents = disabled ? component.disabledEvents + events : component.disabledEvents - events 
}
component_events_disable :: proc{component_events_disable_ptr, component_events_disable_coref}

_component_entity_array_pointer_refresh :: #force_inline proc(component:^ComponentBase){
	component.entity.components[component.myEntityIndex] = component
}
_component_refs_refresh :: proc(component:^$T){ 
	base := cast(^ComponentBase)component

	for crr in base.entity.componentRefRefs[base.myEntityIndex]{
		componentIntAddress := int(uintptr(base.entity.components[crr.refIndex]))
		ref := cast(^CoRef(T))(uintptr(componentIntAddress + crr.refOffset))
		ref._ptr = component
	}
}

_entity_pointers_refresh :: proc(entity:^Entity){
	for i in 0..<entity.requiredComponentCount{
		entity.components[i].entity = entity
	}
	
	for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
		entity.components[i].entity = entity
	}

	entities._id_map[entity.id] = entity
}

_entities_event_process :: proc(event:Event){
    for id in entities.component_type_event_register[event]{
        entities.component_type_metadata[id].process_array(event)
    }
}

/*
When an entity is created, its components are placed arbitrarily on the heap (since the component arrays might not be large enough to contain them).
This proc is called at the end of the update loop (and immediately after a stage is loaded) and appends the newly created components to their respective component arrays.
The append_to_array function handles updating references to it (and other array components if an array resize is necessary), it also frees the memory used to store the buffered component.
The same process occurs for components that were added after an entity was "just created", temporary references these are stored in a dynamic array. In theory all new components could be handled this way, but keeping track of new entities alone helps compress some work.
*/
_entities_just_made_process :: proc(){
	for ref in entities._just_added_buffer{
		component := ref.entity.components[ref.ind]
		component = entities.component_type_metadata[component.coID].append_to_array(component)
		ref.entity.components[ref.ind] = component
		component_event_process(component, .justMade, false)
	}
	clear(&entities._just_added_buffer)

	for i:=0;i<len(entities._just_made_buffer);i+=1{ //since buffer might expand during loop, traditional for loop is necessary
		entity := &entities._just_made_buffer[i]
		for j in 0..<entity.requiredComponentCount{
			component := entity.components[j]
			component = entities.component_type_metadata[component.coID].append_to_array(component)
			entity.components[j] = component
			component_event_process(component, .justMade, false)
		}
		
		for j in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			component := entity.components[j]
			component = entities.component_type_metadata[component.coID].append_to_array(component)
			entity.components[j] = component
			component_event_process(component, .justMade, false)
		}
	}
	entities._just_made_buffer = entities._list[0:][:0]
	
}

_entities_destruction_process :: proc(){
	if(len(entities._destroy_list) == 0) do return
	componentDestroy :: proc(entry:componentDestroyEntry){
		entry.metadata.process(entry.ptr, .clean)
		entry.metadata.remove_from_array(entry.index)
	}
	componentDestroyEntry :: struct{
		ptr:^ComponentBase,
		index:int,
		metadata:^ComponentTypeMetadata
	}

	componentDestroyQueue := make([dynamic]componentDestroyEntry, 0, len(entities._destroy_list)*4, context.temp_allocator)

	for entity in entities._destroy_list{
		for i in 0..<entity.requiredComponentCount{
			component := entity.components[i]
			metadata := &(entities.component_type_metadata[component.coID])
			append(&componentDestroyQueue, componentDestroyEntry{
				component,
				metadata.get_component_index(component),
				metadata
			})
		}
		
		for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			component := entity.components[i]
			metadata := &(entities.component_type_metadata[component.coID])
			append(&componentDestroyQueue, componentDestroyEntry{
				component,
				metadata.get_component_index(component),
				metadata
			})
		}
	}

	sort(&componentDestroyQueue, proc(a,b:componentDestroyEntry)->bool{return a.index < b.index})

	for len(componentDestroyQueue) > 0{
		componentDestroy(pop(&componentDestroyQueue))
	}

	for entity in entities._destroy_list{
		for i in 0..<entity.requiredComponentCount{
			delete(entity.componentRefRefs[i])
		}
		for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			delete(entity.componentRefRefs[i])
		}

		entity_persistent_set(entity, false) //removes entity from persistent list if applicable
		delete_key(&entities._id_map, entity.id)
		index := entity_index_get(entity)
		unordered_remove(&entities._list, index)

		if(len(entities._list) > index) do _entity_pointers_refresh(entity)
	}

	clear(&entities._destroy_list)
}

_entities_clear_all :: proc(){

	//store persistent components and entities elsewhere on the heap
	persistentEntitiesBuffer := make([dynamic]Entity, len(entities._persistent_list), context.temp_allocator)
	for i in 0..<len(entities._persistent_list){
		entity := entity_get(entities._persistent_list[i])
		for j in 0..<entity.requiredComponentCount{
			component := entity.components[j]
			metadata := entities.component_type_metadata[component.coID]
			entity.components[j] = metadata.move_to_heap(metadata.get_component_index(component))
		}
		for j in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			component := entity.components[j]
			metadata := entities.component_type_metadata[component.coID]
			entity.components[j] = metadata.move_to_heap(metadata.get_component_index(component))
		}
		persistentEntitiesBuffer[i] = entity^
	}

	//call clean up events
	_entities_event_process(.clean)

	//clear component arrays and entity list, deactivate all component types
	for coID in CoID{
		if(entities.active_component_types[coID]){
			entities.component_type_metadata[coID].clear_array()
			entities.active_component_types[coID] = false
		}
	}

	for e in Event{
		clear(&entities.component_type_event_register[e])
	}

	for entity in entities._list{
		if(entity.persistent) do continue
		for i in 0..<entity.requiredComponentCount{
			delete(entity.componentRefRefs[i])
		}
		for i in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			delete(entity.componentRefRefs[i])
		}
	}
	clear(&entities._list)
	clear(&entities._id_map)
	clear(&entities._destroy_list)
	
	//move persistent entities and components back into the arrays and reactivate their component types
	resize(&entities._list, len(persistentEntitiesBuffer))
	for i in 0..<len(persistentEntitiesBuffer){
		entities._list[i] = persistentEntitiesBuffer[i]
		_entity_pointers_refresh(&entities._list[i])
	}

	for i in 0..<len(entities._list){
		entity := &entities._list[i]
		for j in 0..<entity.requiredComponentCount{
			component := entity.components[j]
			metadata := entities.component_type_metadata[component.coID]
			entity.components[j] = metadata.append_to_array(component)
			_component_type_activate(component.coID)
		}
		for j in COMPONENTS_MAX_PER_ENTITY..<COMPONENTS_MAX_PER_ENTITY+entity.uniqueComponentCount{
			component := entity.components[j]
			metadata := entities.component_type_metadata[component.coID]
			entity.components[j] = metadata.append_to_array(component)
			_component_type_activate(component.coID)
		}
	}
}
