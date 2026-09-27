varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform sampler2D u_noise;
uniform float u_burn;

void main()
{
    vec4 col = texture2D(texture0, fragTexCoord) * fragColor;
    float n = texture2D(u_noise, fragTexCoord).r;
    float d = n - clamp(u_burn, 0.0, 1.0);
    vec3 outRgb = mix(vec3(1.0, 0.4, 0.1), col.rgb, smoothstep(0.0, 0.08, d));
    gl_FragColor = vec4(outRgb, col.a * step(0.0, d));
}
