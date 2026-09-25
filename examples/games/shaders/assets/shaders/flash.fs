// White hit-flash. u_flash 0 = normal sprite, 1 = fully white.
// NOTE: the effect applies AFTER texel * fragColor. Untextured shapes
// sample a 1x1 white texture, so grading texel.rgb alone is a no-op on them.
varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform float u_flash;

void main()
{
    vec4 col = texture2D(texture0, fragTexCoord) * fragColor;
    float amount = clamp(u_flash, 0.0, 1.0);
    vec3 outRgb = mix(col.rgb, vec3(1.0), amount);
    gl_FragColor = vec4(outRgb, col.a);
}
