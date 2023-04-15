#include "kernel.h"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include<thrust/complex.h>
 #define TX 32
 #define TY 32
#define max_iteration 500

 __device__
 unsigned char clip(int n) { return n > 255 ? 255 : (n < 0 ? 0 : n); }

 __global__
 void distanceKernel(uchar4 * d_out, int w, int h, int2 pos) {
	const int c = blockIdx.x * blockDim.x + threadIdx.x;
	const int r = blockIdx.y * blockDim.y + threadIdx.y;
	if ((c >= w) || (r >= h)) return; // Check if within image bounds
	const int i = c + r * w; // 1D indexing
	const int dist = sqrtf((c - pos.x) * (c - pos.x) +
	 (r - pos.y) * (r - pos.y));
	 const unsigned char intensity = clip(255 - dist);
	 d_out[i].x = intensity;
	 d_out[i].y = intensity;
	 d_out[i].z = 0;
	 d_out[i].w = 255;
	
}
 __global__ void juliaset(uchar4* d_out,int w , int h,thrust::complex<double> c, float zoom ,  double2 offset) {
	 const int o = blockIdx.x * blockDim.x + threadIdx.x;
	 const int r = blockIdx.y * blockDim.y + threadIdx.y;
	 int2 cen = { w / 2,h / 2 };
	 
	 if ((o >= w) || (r >= h)) return; // Check if within image bounds
	 const int i = o + r * w; // 1D indexing
	 thrust::complex<double > pos = { (zoom * 3 * (double(o - cen.x) / w)) + offset.x,(zoom * 3 * (double(r - cen.y) / h)) + offset.y };
	 thrust::complex<double> z = { pos.real(),pos.imag()};
	 
	 int j = 0;
	 for ( j; j < max_iteration; j++) {
		 if (thrust::abs(z ) > 4) break;
		 z =  z*z + c;
		 
	 }
	 double smooth = (double(j) - log2(fmax(1.0, log2(thrust::abs(z ))))) / max_iteration;
	 unsigned char intensity = char(255*smooth);
	 
	 d_out[i].x = intensity;
	 d_out[i].y = intensity;
	 d_out[i].z =intensity;
	 d_out[i].w = 255;
 }
 void kernelLauncher(uchar4 * d_out, int w, int h, double2 pos, float zoom,double2 offset) {
	 const dim3 blockSize(TX, TY);
	 const dim3 gridSize = dim3((w + TX - 1) / TX, (h + TY - 1) / TY);
	 thrust::complex<double> c = { pos.x,pos.y };
	 juliaset << <gridSize, blockSize >> > (d_out, w, h, c, zoom, offset);
	 cudaDeviceSynchronize();
	
}
