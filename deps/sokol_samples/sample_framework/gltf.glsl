@vs vs
uniform vs_params {
    mat4 view_projection;
    mat4 model;
};

in vec4 position;
in vec3 normal;

out vec4 color;

void main() {
    gl_Position = view_projection * model  * position;
    color = vec4(normal, 1);
}
@end

@fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program gltf vs fs
