package massimodin //@nested-tags:libraries/steamworks

SteamworksSystem :: struct{
	enabled:bool,
}
steamworks:^SteamworksSystem

_steamworks_init :: proc(){
	steamworks = new(SteamworksSystem)
	//[redacted]
}

_steamworks_update :: proc(){
	//[redacted]
}

_steamworks_shutdown :: proc(){
	//[redacted]
}

_steamworks_stats_init :: proc() -> bool{
	//[redacted]
	return false
}

//reads current save data to update steam player stats
steamworks_stats_update_and_push :: proc(){
	//[redacted]
}
