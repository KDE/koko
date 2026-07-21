#version 440

layout(location = 0) in vec2 texCoord;
layout(location = 1) in vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float gamma;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    fragColor = texture(source, texCoord);
    fragColor.rgb = fragColor.rgb / max(1.0 / 256.0, fragColor.a);
    vec3 adjustedColor = pow(fragColor.rgb, vec3(1.0 / gamma));
    fragColor = vec4(adjustedColor * fragColor.a, fragColor.a) * qt_Opacity;
}
