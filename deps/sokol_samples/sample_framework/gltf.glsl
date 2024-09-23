@vs vs
uniform vs_params {
    mat4 projection_view;
    mat4 model;
};

in vec3 aPos;
in vec3 aNormal;
in vec2 aTexCoord;

out vec3 FragPos;  
out vec3 Normal;
out vec2 TexCoord;

void main() {
    gl_Position = projection_view * model  * vec4(aPos, 1.0);
    FragPos = vec3(model * vec4(aPos, 1.0));
    Normal = aNormal;
    TexCoord = aTexCoord;
}
@end

@fs fs
uniform fs_params {
    vec3 lightPos;  
};
uniform submesh_params {
    vec4 material_rgba;
};

uniform texture2D colorTexture2D;
uniform sampler colorTextureSmp;
#define colorTexture sampler2D(colorTexture2D, colorTextureSmp)

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;
out vec4 frag_color;

void main() {
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);  
    float diff = max(dot(norm, lightDir), 0.0);
    vec4 texel = texture(colorTexture, TexCoord);
    // vec3 diffuse = diff * lightColor;
    frag_color = texel * vec4(
        material_rgba.r * diff, 
        material_rgba.g * diff, 
        material_rgba.b * diff, 
        material_rgba.a);
}
@end

@program gltf vs fs
