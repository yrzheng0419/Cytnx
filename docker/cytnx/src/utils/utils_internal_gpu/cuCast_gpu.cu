#include "utils/utils_internal_gpu/cuCast_gpu.hpp"
#include "Storage.hpp"
#ifdef UNI_OMP
#include <omp.h>
#endif

using namespace std;
namespace cytnx{
    namespace utils_internal{


        __global__ void cuCastElem_kernel_cd2cf(const cuDoubleComplex *src, cuFloatComplex *des, cytnx_uint64 Nelem){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                des[blockIdx.x*blockDim.x + threadIdx.x] = cuComplexDoubleToFloat(src[blockIdx.x*blockDim.x + threadIdx.x]);
            }
        }

        __global__ void cuCastElem_kernel_cf2cd(const cuFloatComplex *src, cuDoubleComplex *des, cytnx_uint64 Nelem){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                des[blockIdx.x*blockDim.x + threadIdx.x] = cuComplexFloatToDouble(src[blockIdx.x*blockDim.x + threadIdx.x]);
            }
        }
        
        template<class T>
        __global__ void cuCastElem_kernel_r2cf(const T *src, cuFloatComplex *des, cytnx_uint64 Nelem){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                des[blockIdx.x*blockDim.x + threadIdx.x].x = src[blockIdx.x*blockDim.x + threadIdx.x];
            }
        }
        template<class T2>
        __global__ void cuCastElem_kernel_r2cd(const T2 *src, cuDoubleComplex *des, cytnx_uint64 Nelem){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                des[blockIdx.x*blockDim.x + threadIdx.x].x = src[blockIdx.x*blockDim.x + threadIdx.x];
            }
        }

        template<class T3,class T4>
        __global__ void cuCastElem_kernel_r2r(const T3 *src, T4 *des, cytnx_uint64 Nelem){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                des[blockIdx.x*blockDim.x + threadIdx.x] = src[blockIdx.x*blockDim.x + threadIdx.x];
            }
        }

        //========================================================================
        void cuCast_gpu_cdtcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_complex128)*len_in,cudaMemcpyDeviceToDevice)); 
        }

        void cuCast_gpu_cdtcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }

            cuDoubleComplex* _in = static_cast<cuDoubleComplex*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_cd2cf<<<NBlocks,512>>>(_in,_out,len_in);

        }

        void cuCast_gpu_cftcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cuFloatComplex* _in = static_cast<cuFloatComplex*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);
            
            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_cf2cd<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_cftcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_complex64)*len_in,cudaMemcpyDeviceToDevice)); 
        }


        void cuCast_gpu_dtcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){

            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cd<<<NBlocks,512>>>(_in,_out,len_in);

        }

        void cuCast_gpu_dtcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());    
                out->Init(len_in,alloc_device);
            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cf<<<NBlocks,512>>>(_in,_out,len_in);

        }

        void cuCast_gpu_dtd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){       
                out = boost::intrusive_ptr<Storage_base>(new DoubleStorage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_double)*len_in,cudaMemcpyDeviceToDevice)); 

        }
        void cuCast_gpu_dtf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new FloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cytnx_float*  _out= static_cast<cytnx_float*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_dti64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cytnx_int64*  _out= static_cast<cytnx_int64*>(out->Mem);
            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_dtu64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cytnx_uint64*  _out= static_cast<cytnx_uint64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_dti32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int32Storage());
                out->Init(len_in,alloc_device);

            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cytnx_int32*  _out= static_cast<cytnx_int32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_dtu32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_double* _in = static_cast<cytnx_double*>(in->Mem);
            cytnx_uint32*  _out= static_cast<cytnx_uint32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);

        }

        void cuCast_gpu_ftcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cd<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_ftcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cf<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_ftd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new DoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cytnx_double*  _out= static_cast<cytnx_double*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_ftf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new FloatStorage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_float)*len_in,cudaMemcpyDeviceToDevice)); 
        }
        void cuCast_gpu_fti64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cytnx_int64*  _out= static_cast<cytnx_int64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_ftu64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cytnx_uint64*  _out= static_cast<cytnx_uint64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_fti32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cytnx_int32*  _out= static_cast<cytnx_int32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_ftu32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_float* _in = static_cast<cytnx_float*>(in->Mem);
            cytnx_uint32*  _out= static_cast<cytnx_uint32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_i64tcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cd<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i64tcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cf<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_i64td(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new DoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cytnx_double*  _out= static_cast<cytnx_double*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_i64tf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new FloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cytnx_float*  _out= static_cast<cytnx_float*>(out->Mem);


            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_i64ti64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int64Storage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_int64)*len_in,cudaMemcpyDeviceToDevice)); 

        }
        void cuCast_gpu_i64tu64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cytnx_uint64*  _out= static_cast<cytnx_uint64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i64ti32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cytnx_int32*  _out= static_cast<cytnx_int32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i64tu32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int64* _in = static_cast<cytnx_int64*>(in->Mem);
            cytnx_uint32*  _out= static_cast<cytnx_uint32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_u64tcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cd<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_u64tcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cf<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_u64td(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new DoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cytnx_double*  _out= static_cast<cytnx_double*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u64tf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new FloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cytnx_float*  _out= static_cast<cytnx_float*>(out->Mem);


            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u64ti64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cytnx_int64*  _out= static_cast<cytnx_int64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u64tu64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint64Storage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_uint64)*len_in,cudaMemcpyDeviceToDevice)); 
           
        }
        void cuCast_gpu_u64ti32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cytnx_int32*  _out= static_cast<cytnx_int32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u64tu32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint64* _in = static_cast<cytnx_uint64*>(in->Mem);
            cytnx_uint32*  _out= static_cast<cytnx_uint32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_i32tcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cd<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i32tcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cf<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i32td(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new DoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cytnx_double*  _out= static_cast<cytnx_double*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i32tf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new FloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cytnx_float*  _out= static_cast<cytnx_float*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i32ti64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cytnx_int64*  _out= static_cast<cytnx_int64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i32tu64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cytnx_uint64*  _out= static_cast<cytnx_uint64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_i32ti32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int32Storage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_int32)*len_in,cudaMemcpyDeviceToDevice)); 
        }
        void cuCast_gpu_i32tu32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_int32* _in = static_cast<cytnx_int32*>(in->Mem);
            cytnx_uint32*  _out= static_cast<cytnx_uint32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }

        void cuCast_gpu_u32tcd(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexDoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cuDoubleComplex*  _out= static_cast<cuDoubleComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cd<<<NBlocks,512>>>(_in,_out,len_in);

        }
        void cuCast_gpu_u32tcf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new ComplexFloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cuFloatComplex*  _out= static_cast<cuFloatComplex*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2cf<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u32td(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new DoubleStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cytnx_double*  _out= static_cast<cytnx_double*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u32tf(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new FloatStorage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cytnx_float*  _out= static_cast<cytnx_float*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u32ti64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cytnx_int64*  _out= static_cast<cytnx_int64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u32tu64(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint64Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cytnx_uint64*  _out= static_cast<cytnx_uint64*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u32ti32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Int32Storage());
                out->Init(len_in,alloc_device);
            }
            cytnx_uint32* _in = static_cast<cytnx_uint32*>(in->Mem);
            cytnx_int32*  _out= static_cast<cytnx_int32*>(out->Mem);

            cytnx_uint64 NBlocks = len_in/512;
            if(len_in%512) NBlocks+=1;
            cuCastElem_kernel_r2r<<<NBlocks,512>>>(_in,_out,len_in);
        }
        void cuCast_gpu_u32tu32(const boost::intrusive_ptr<Storage_base>& in, boost::intrusive_ptr<Storage_base>& out, const unsigned long long &len_in, const int &alloc_device){
            if(alloc_device>=0){
                out = boost::intrusive_ptr<Storage_base>(new Uint32Storage());
                out->Init(len_in,alloc_device);
            }
            checkCudaErrors(cudaMemcpy(out->Mem,in->Mem,sizeof(cytnx_uint32)*len_in,cudaMemcpyDeviceToDevice)); 

        }
    }//namespace utils_internal
}//namespace cytnx