Texture2D<float4> src : register(t0);
SamplerState samp : register(s0);
cbuffer constant0 : register(b0) {
    float2 resolution;
    float round_unit;
    float round;
    float border_unit;
    float border_width;
    float4 border_color;
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

float4 round_border(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 st = (2.0 * pos.xy - resolution.xy) / min(resolution.x, resolution.y);
    float2 box_size = resolution.xy / min(resolution.x, resolution.y);
    float px_to_st = 2.0 / min(resolution.x, resolution.y);

    // 角丸半径
    float r_ = (round_unit == 1.0)
        ? min(box_size.x, box_size.y) * round
        : round * px_to_st;
    r_ = min(r_, min(box_size.x, box_size.y));

    // 枠幅
    float bw_ = (border_unit == 1.0)
        ? min(box_size.x, box_size.y) * border_width
        : border_width * px_to_st;
    bw_ = max(bw_, 0.0);

    float d = sdRoundBox(st, box_size, r_);
    float pixel_w = max(length(float2(ddx(d), ddy(d))), 1e-5);

    float outer = smoothstep(pixel_w * 0.5, -pixel_w * 0.5, d);
    float inner = smoothstep(-bw_ - pixel_w * 0.5, -bw_ + pixel_w * 0.5, d);
    float has_border = step(1e-5, bw_);
    float border_mask = outer * inner * has_border;

    float4 tex = src.Sample(samp, uv);

    float4 tex_rounded = tex;
    tex_rounded.a *= outer;

    float4 border_masked = border_color;
    border_masked.a *= border_mask;

    return overBlend(border_masked, tex_rounded);
}