#version 330
in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;
uniform sampler2D texture0;
uniform float u_time;
uniform float u_speed;
uniform float u_hit;

void main()
{
    vec2 uv = fragTexCoord - 0.5;
    float edge = dot(uv, uv);
    uv *= 1.0 + edge * (0.035 + u_speed * 0.08);
    uv += 0.5;
    float split = 0.0015 + u_hit * 0.010;
    vec3 col;
    col.r = texture(texture0, uv + vec2(split, 0.0)).r;
    col.g = texture(texture0, uv).g;
    col.b = texture(texture0, uv - vec2(split, 0.0)).b;
    float scan = 0.97 + sin(fragTexCoord.y * 720.0 + u_time * 20.0) * 0.025;
    col *= scan;
    col += vec3(0.025, 0.0, 0.06) * edge;
    finalColor = vec4(col, 1.0) * fragColor;
}
