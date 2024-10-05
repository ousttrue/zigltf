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
            name: 'glTF-Tutorials',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_003_MinimalGltfFile.html',
          },
        ],
      },
      {
        name: 'sparse',
        links: [
          {
            name: 'glTF-Tutorials',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_005_BuffersBufferViewsAccessors.html',
          },
        ],
      },
      {
        name: 'animation',
        links: [
          {
            name: 'glTF-Tutorials',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_006_SimpleAnimation.html',
          },
        ],
      },
      {
        name: 'simple_meshes',
        links: [
          {
            name: 'glTF-Tutorials',
            url: 'https://github.khronos.org/glTF-Tutorials/gltfTutorial/gltfTutorial_008_SimpleMeshes.html',
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
            name: 'github',
            url: 'https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_draco_mesh_compression/README.md',
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
    ],
  },
];
