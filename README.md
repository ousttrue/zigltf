# zigltf

zig gltf library.

## build

`zig-0.13.0`

```sh
> zig build -Dsokol run-minimal
```

wasm build.

```sh
> zig build -Dsokol -Dtarget=wasm32-emscripten
```

## features

- [x] [minimal](https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_003_MinimalGltfFile.html)
- [x] [glb](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/CesiumMilkTruck/glTF-Binary)
  - [x] node
  - [x] texture
  - [ ] animation
- [ ] glTF
- [ ] draco
- [ ] basisu
- [ ] vrm-0.x
- [ ] vrm-1.0
