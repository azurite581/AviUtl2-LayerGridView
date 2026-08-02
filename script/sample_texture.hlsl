Texture2D<float4> src : register(t0);
SamplerState samp : register(s0);
cbuffer constant0 : register(b0) {
    float2 resoltion;
    float2 src_resolution;
    float scale_mode;
    float scale;
    float sampler_mode;
    float pad;
    float zoom;
    float alpha;
    float2 offset;
    float4 bg_col;
    float2x2 angle;
}

// 2D SDF functions (https://iquilezles.org/articles/distfunctions2d/) by Inigo Quilez
// Copyright © 2020 Inigo Quilez
// Licensed under the MIT License.
float sdRoundBox(in float2 p, in float2 b, in float4 r)
{
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x  = (p.y > 0.0) ? r.x  : r.y;
    float2 q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float4 overBlend(float4 src, float4 dst)
{
    float out_a = src.a + dst.a * (1.0 - src.a);
    float3 out_rgb = src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a);
    return float4(out_rgb, out_a);
}

float4 sample_texture(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 displayed_size = src_resolution * scale;
    float2 p = (pos.xy - (resoltion - displayed_size) * 0.5) / displayed_size;
    float aspect = displayed_size.x / displayed_size.y;

    if ((int)scale_mode == 2) {
        p = pos.xy / resoltion;
        aspect = resoltion.x / resoltion.y;
    }

    p -= offset;
    p -= 0.5;

    p.x *= aspect;
    p = mul(angle, p) / zoom;
    p.x /= aspect;

    p += 0.5;
    float4 sampled = src.Sample(samp, p);
    sampled.rgb = sampled.rgb + bg_col.rgb * (1.0 - sampled.a);
    sampled.a = 1.0;

    bool in_bounds = (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0);
    float4 tex = sampled;
    if ((int)sampler_mode == 0 || (int)sampler_mode == 1) {
        tex = in_bounds ? sampled : bg_col;
    }
    tex *= alpha;

    return tex;
}