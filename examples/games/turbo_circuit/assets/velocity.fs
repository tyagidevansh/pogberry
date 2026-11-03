#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;

uniform float u_time;
uniform float u_speed;
uniform float u_intensity;
uniform vec2 u_resolution;

// Clean high-speed peripheral streaks
float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main()
{
    vec2 res = u_resolution;
    if (res.x <= 0.0 || res.y <= 0.0) res = vec2(1280.0, 720.0);
    vec2 p = (gl_FragCoord.xy - 0.5 * res) / res.y;
    p.y -= 0.02; // Center slightly above car hood

    float r = length(p);
    float boost = clamp(u_intensity, 0.0, 1.0);

    // Keep central racing surface completely clear
    if (boost <= 0.001 || r < 0.28) {
        finalColor = vec4(0.0);
        return;
    }

    float angle = atan(p.y, p.x);
    float aNorm = (angle + 3.14159265) / 6.2831853;

    // High-frequency peripheral speed rays
    float rayBin = floor(aNorm * 110.0);
    float rayRnd = hash1(rayBin * 23.47);
    float rayActive = step(0.65, rayRnd);

    // Fast outward motion along rays
    float motion = fract(r * 3.8 - u_time * (10.0 + u_speed * 12.0) + rayRnd * 3.0);
    float pulse = smoothstep(0.0, 0.25, motion) * smoothstep(1.0, 0.45, motion);

    // Smooth outward radial mask (unobtrusive peripheral effect)
    float radialFade = smoothstep(0.28, 0.80, r);
    float streakAlpha = rayActive * pulse * radialFade * boost * 0.45;

    // Elegant ice-cyan and white streaks matching the arcade HUD
    vec3 streakCol = mix(vec3(0.0, 0.94, 1.0), vec3(1.0, 1.0, 1.0), rayRnd);

    // Subtle edge speed glow
    float edgeGlow = smoothstep(0.85, 1.45, dot(p, p) * 2.2) * boost * 0.15;
    vec3 glowCol = vec3(0.0, 0.75, 1.0);

    vec3 finalRgb = streakCol * streakAlpha + glowCol * edgeGlow;
    float finalA = clamp(streakAlpha + edgeGlow, 0.0, 0.55);

    finalColor = vec4(finalRgb, finalA);
}
