// Grayscale responding to time, driven by u_intensity.
// NOTE: the effect applies AFTER texel * fragColor. Untextured shapes
// sample a 1x1 white texture, so grading texel.rgb alone is a no-op on them.
varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform float u_intensity;

void main()
{
    vec4 col = texture2D(texture0, fragTexCoord) * fragColor;
    float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    vec3 outRgb = mix(col.rgb, vec3(gray), clamp(u_intensity, 0.0, 1.0));
    gl_FragColor = vec4(outRgb, col.a);
}
