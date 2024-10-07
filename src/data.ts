export type LinkType = {
  name: string,
  url: string,
};
export type ItemType = {
  name: string,
  links: LinkType[],
};
export type ItemGroupType = {
  name: string,
  url: string,
  items: ItemType[],
};

export const GROUPS: ItemGroupType[] = [
  {
    name: 'glTF Tutorial',
    url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/',
    items: [
      {
        name: 'minimal',
        links: [
          {
            name: 'Tutorial-003',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_003_MinimalGltfFile.html',
          },
        ],
      },
      {
        name: 'sparse',
        links: [
          {
            name: 'Tutorial-005',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_005_BuffersBufferViewsAccessors.html',
          },
        ],
      },
      {
        name: 'animation',
        links: [
          {
            name: 'Tutorial-006',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_006_SimpleAnimation.html',
          },
        ],
      },
      {
        name: 'simple_meshes',
        links: [
          {
            name: 'Tutorial-008',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_008_SimpleMeshes.html',
          },
        ],
      },
      {
        name: 'simple_material',
        links: [
          {
            name: 'Tutorial-011',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_011_SimpleMaterial.html',
          },
        ],
      },
      {
        name: 'simple_texture',
        links: [
          {
            name: 'Tutorial-013',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_013_SimpleTexture.html',
          },
        ],
      },
      {
        name: 'morphtarget',
        links: [
          {
            name: 'Tutorial-017',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_017_SimpleMorphTarget.html',
          },
        ],
      },
      {
        name: 'skin',
        links: [
          {
            name: 'Tutorial-019',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_019_SimpleSkin.html',
          },
        ],
      },
    ],
  },
  {
    name: 'glTF-2.0',
    url: 'https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html',
    items: [
      {
        name: 'glb',
        links: [
          {
            name: 'glb',
            url: 'https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#glb-file-format-specification',
          },
        ],
      },
      {
        name: 'gltf',
        links: [
          {
            name: 'gltf',
            url: 'https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html',
          },
        ],
      },
      {
        name: 'draco',
        links: [
          {
            name: 'KHR_draco_mesh_compression',
            url: 'https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_draco_mesh_compression/README.md',
          },
        ],
      },
      {
        name: 'basisu',
        links: [
          {
            name: 'KHR_texture_basisu',
            url: 'https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_texture_basisu/README.md',
          },
        ],
      },
      {
        name: 'unlit',
        links: [
          {
            name: 'KHR_materials_unlit',
            url: 'https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_unlit',
          },
        ],
      },
      {
        name: 'emission',
        links: [
          {
            name: 'KHR_materials_emissive_strength',
            url: 'https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_emissive_strength',
          },
        ],
      },
      {
        name: 'vrm0',
        links: [
          {
            name: 'vrm-0.x',
            url: 'https://github.com/vrm-c/vrm-specification/blob/master/specification/0.0/README.ja.md',
          },
        ],
      },
      {
        name: 'vrm1',
        links: [
          {
            name: 'VRMC_vrm',
            url: 'https://github.com/vrm-c/vrm-specification/tree/master/specification/VRMC_vrm-1.0',
          },
        ]
      },
    ],
  },
];
