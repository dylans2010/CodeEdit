#include <metal_stdlib>
using namespace metal;

vertex float4 vertexShader(uint vertexID [[vertex_id]]) {
    float2 positions[3] = { float2(0.0, 0.5), float2(-0.5, -0.5), float2(0.5, -0.5) };
    return float4(positions[vertexID], 0.0, 1.0);
}

fragment float4 fragmentShader() {
    return float4(0.2, 0.6, 1.0, 1.0);
}
