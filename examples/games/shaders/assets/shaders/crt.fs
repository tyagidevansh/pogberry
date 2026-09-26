varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform float u_time;

void main()
{
    vec2 uv = fragTexCoord;
    vec4 col = texture2D(texture0, uv) * fragColor;
    float scan = 0.9 + 0.1 * sin(uv.y * 450.0 + u_time * 8.0);
    float dx = uv.x - 0.5;
    float dy = uv.y - 0.5;
    float vig = clamp(1.0 - (dx * dx + dy * dy) * 0.9, 0.0, 1.0);
    gl_FragColor = vec4(col.rgb * scan * vig, col.a);
}
