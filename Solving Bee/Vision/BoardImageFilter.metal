#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {
    namespace coreimage {
        float4 boardImageKernel(sampler src) {
            float4 input = src.sample(src.coord());
            float luma = dot(input.rgb, float3(0.2126, 0.7152, 0.0722));
            if (luma < 0.2) {
                return float4(0.0, 0.0, 0.0, 1.0);
            }
            return float4(1.0, 1.0, 1.0, 1.0);
        }
    }
}
