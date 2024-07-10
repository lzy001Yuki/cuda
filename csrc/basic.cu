#include <cassert>
#include <chrono>
#include <cstdio>
#include <cublas_v2.h>
#include <cuda_runtime.h>
#include <random>

// You may increase this value to test larger matrices
// But it will be slow on CPU
constexpr int MAXN = 1 << 28;

void vectorAddCPU(float *a, float *b, float *c, const int N) {
    for (int i = 0; i < N; ++i) {
        c[i] = a[i] + b[i];
    }
}

void initialize(float *a, float *b, const int N) {
    auto gen = std::mt19937(2024);
    auto dis = std::uniform_real_distribution<float>(-1.0, 1.0);
    for (int i = 0; i < N; ++i) {
        a[i] = dis(gen);
    }
    for (int i = 0; i < N; ++i) {
        b[i] = dis(gen);
    }
}

bool compare(float *a, float *b, const int N) {
    for (int i = 0; i < N; ++i) {
        if (std::abs(a[i] - b[i]) > 1e-3) {
            printf("Mismatch at index %d: %f vs %f\n", i, a[i], b[i]);
            return false;
        }
    }
    printf("Results match\n");
    return true;
}

__global__ void vectorAddGPU(float *a, float *b, float *c, const int N) {
    // Implement your vector add kernel here
    index = blockDim.x * blockIdx.x + threadIdx.x;
    if (index < N) {
        c[index] = a[index] + b[index];
    }
}

int main() {
    float *a, *b, *c;
    a = new float[MAXN];
    b = new float[MAXN];
    c = new float[MAXN];
    initialize(a, b, MAXN);

    // CPU computation
    auto start = std::chrono::high_resolution_clock::now();
    vectorAddCPU(a, b, c, MAXN);
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> elapsed = end - start;
    printf("CPU time: %.3fs\n", elapsed.count());

    // ************** START GPU MEMORY ALLOCATION **************
    // Implement your code here
    // MAXN --size of the vector
    // allocate memory for GPU
    float *a_gpu, *b_gpu, *c_gpu;
    cudaMalloc(a_gpu, sizeof(float) * MAXN);
    cudaMalloc(b_qpu, sizeof(float) * MAXN);
    cudaMalloc(c_gpu, sizeof(float) * MAXN);

    // copy
    cudaMemcpy(a_gpu, a, MAX * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(b_gpu, b, MAX * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(c_gpu, c, MAX * sizeof(float), cudaMemcpyHostToDevice);

    // define size of block and grid
    int threadSize = 256;
    int blockSize = (MAXN + threadSize - 1) / threadSize;
    // ************** START GPU COMPUTATION **************
    start = std::chrono::high_resolution_clock::now();
    // Implement your code here
    vectorAddGPU<<<blockSize, threadSize>>>(a_gpu, b_gpu, c_gpu, MAXN);
    cudaDeviceSynchronize();
    end = std::chrono::high_resolution_clock::now();
    float *result = new float[MAXN];
    // Copy the result from GPU to CPU
    cudaMemcpy(result, c_gpu, MAXN * sizeof(float), cudaMemcpyDeviceToHost);
    if (compare(c, result, MAXN)) {
        std::chrono::duration<double> new_elapsed = end - start;
        printf("GPU time: %.3fs\n", new_elapsed.count());
        printf("Speedup: %.2fx\n", elapsed.count() / new_elapsed.count());
    }
}