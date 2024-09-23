@vs vs
uniform vs_params {
    mat4 projection_view;
    mat4 model;
};

in vec3 aPos;
in vec3 aNormal;

out vec3 FragPos;  
out vec3 Normal;

void main() {
    gl_Position = projection_view * model  * vec4(aPos, 1.0);
    FragPos = vec3(model * vec4(aPos, 1.0));
    Normal = aNormal;
}
@end

@fs fs
uniform fs_params {
    vec3 lightPos;  
};

in vec3 FragPos;
in vec3 Normal;
out vec4 frag_color;

void main() {
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);  
    float diff = max(dot(norm, lightDir), 0.0);
    // vec3 diffuse = diff * lightColor;
    frag_color = vec4(diff, diff, diff, 1.0);
}
@end

@program gltf vs fs
