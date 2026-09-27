varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 u_tint;
uniform vec3 u_glow;
uniform vec4 u_rect;

void main()
{
    vec4 col = texture2D(texture0, fragTexCoord) * fragColor;
    col.rgb *= u_tint.rgb * u_tint.a;
    float inside = step(u_rect.x, fragTexCoord.x) * step(fragTexCoord.x, u_rect.x + u_rect.z)
        * step(u_rect.y, fragTexCoord.y) * step(fragTexCoord.y, u_rect.y + u_rect.w);
    col.rgb += u_glow * inside;
    gl_FragColor = col;
}
