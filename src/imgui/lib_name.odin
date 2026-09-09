package imgui

when      ODIN_OS == .Windows      { OS :: "windows" }
else when ODIN_OS == .Darwin       { OS :: "darwin" }
else when ODIN_OS == .Linux        { OS :: "linux" }
else when ODIN_OS == .FreeBSD      { OS :: "freebsd" }
else                               { OS :: "unknown" }

when      ODIN_ARCH == .amd64      { ARCH :: "x64" }
else when ODIN_ARCH == .arm64      { ARCH :: "arm64" }
else when ODIN_ARCH == .wasm32     { ARCH :: "wasm32" }
else when ODIN_ARCH == .wasm64p32  { ARCH :: "wasm64" }
else                               { ARCH :: "unknown" }

when ODIN_OS == .Windows {
	IMGUI_LIB_NAME :: "imgui_" + OS + "_" + ARCH + ".lib"
} else {
	IMGUI_LIB_NAME :: "imgui_" + OS + "_" + ARCH + ".a"
}
