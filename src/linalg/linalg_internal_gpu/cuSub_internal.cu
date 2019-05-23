#include "linalg/linalg_internal_gpu/cuSub_internal.hpp"
#include "utils/utils_internal.hpp"

#ifdef UNI_OMP
    #include <omp.h>
#endif

namespace tor10{

    namespace linalg_internal{

        //====================================================================
        //generic R+R kernel
        template<class T1,class T2,class T3>
        __global__ void cuSub_rconst_kernel(T1 *out, const T2 *ptr, const tor10_uint64 Nelem, const T3 val){
              if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                  out[blockIdx.x*blockDim.x + threadIdx.x] = ptr[blockIdx.x*blockDim.x + threadIdx.x] - val;
              }
              __syncthreads();
         }
        
        template<class T1,class T2,class T3>
        __global__ void cuSub_lconst_kernel(T1 *out, const T2 val, const tor10_uint64 Nelem, const T3 *ptr){
              if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                  out[blockIdx.x*blockDim.x + threadIdx.x] = val - ptr[blockIdx.x*blockDim.x + threadIdx.x];
              }
              __syncthreads();
         }
        
        template<class T1,class T2,class T3>
        __global__ void cuSub_tn_kernel(T1 *out, const T2 *val, const tor10_uint64 Nelem, const T3 *ptr){
              if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                  out[blockIdx.x*blockDim.x + threadIdx.x] = val[blockIdx.x*blockDim.x + threadIdx.x] - ptr[blockIdx.x*blockDim.x + threadIdx.x];
              }
              __syncthreads();
        }

        //=====================================================================

        /// cuSub
        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],val);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_cdtcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;
                
           if(Lin->size()==1){
                cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
            }else if(Rin->size()==1){
                cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
            }else{
                cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
            }
        }



        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],cuComplexFloatToDouble(val));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,cuComplexFloatToDouble(ptr[blockIdx.x*blockDim.x + threadIdx.x]));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],cuComplexFloatToDouble(val[blockIdx.x*blockDim.x + threadIdx.x]));
            }
            __syncthreads();
        }
        void cuSub_internal_cdtcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

            if(Lin->size()==1){
                cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
            }else if(Rin->size()==1){
                cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
            }else{
                cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
            }

        }

        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_double val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const tor10_double *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_double *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cdtd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            tor10_double *_Rin = (tor10_double*)Rin->Mem;


            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

            if(Lin->size()==1){
                cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
            }else if(Rin->size()==1){
                cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
            }else{
                cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
            }


        }

        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_float val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const tor10_float *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_float *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){                                                
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cdtf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            tor10_float *_Rin = (tor10_float*)Rin->Mem;


            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

            if(Lin->size()==1){
                cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
            }else if(Rin->size()==1){
                cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
            }else{
                cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
            }



        }


          __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_uint64 val){
              if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                  out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val,0));
              }
              __syncthreads();
          }
          __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const tor10_uint64 *ptr){
              if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                  out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
              }
              __syncthreads();
          }
          __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_uint64 *val){
              if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                  out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
              }
              __syncthreads();
          }

        void cuSub_internal_cdtu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;


            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_uint32 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const tor10_uint32 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_uint32 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cdtu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }



        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_int64 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const tor10_int64 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_int64 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cdti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }


        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_int32 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuDoubleComplex val, const tor10_uint64 Nelem, const tor10_int32 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(val,make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuDoubleComplex *ptr, const tor10_uint64 Nelem, const tor10_int32 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuDoubleComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cdti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuDoubleComplex *_Lin = (cuDoubleComplex*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(cuComplexFloatToDouble(ptr[blockIdx.x*blockDim.x + threadIdx.x]),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const cuFloatComplex val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(cuComplexFloatToDouble(val),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(cuComplexFloatToDouble(ptr[blockIdx.x*blockDim.x + threadIdx.x]),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_cftcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

	    }

        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_cftcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const tor10_double val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_uint64 Nelem, const tor10_double *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const tor10_double *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cftd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            tor10_double *_Rin = (tor10_double*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }



        }

        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const tor10_float val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_uint64 Nelem, const tor10_float *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const tor10_float *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cftf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            tor10_float *_Rin = (tor10_float*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const tor10_uint64 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_uint64 Nelem, const tor10_uint64 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint64 Nelem, const tor10_uint64 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cftu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;
            
            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint32 Nelem, const tor10_uint32 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_uint32 Nelem, const tor10_uint32 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_uint32 Nelem, const tor10_uint32 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cftu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_int64 Nelem, const tor10_int64 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_int64 Nelem, const tor10_int64 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_int64 Nelem, const tor10_int64 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cfti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_int32 Nelem, const tor10_int32 val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val,0));
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const cuFloatComplex val, const tor10_int32 Nelem, const tor10_int32 *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(val,make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const cuFloatComplex *ptr, const tor10_int32 Nelem, const tor10_int32 *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(ptr[blockIdx.x*blockDim.x + threadIdx.x],make_cuFloatComplex(val[blockIdx.x*blockDim.x + threadIdx.x],0));
            }
            __syncthreads();
        }
        void cuSub_internal_cfti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            cuFloatComplex *_Lin = (cuFloatComplex*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        

        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const tor10_double *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const tor10_double val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const tor10_double *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_dtcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const tor10_double *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const tor10_double val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const tor10_double *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_dtcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }


        void cuSub_internal_dtd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            tor10_double *_Rin = (tor10_double*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }
        void cuSub_internal_dtf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            tor10_float *_Rin = (tor10_float*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_dtu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){

            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_dtu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){

            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_dti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){

            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_dti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){

            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_double *_Lin = (tor10_double*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }



        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const tor10_float *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const tor10_float val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const tor10_float *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_ftcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const tor10_float *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const tor10_float val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const tor10_float *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_ftcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }

        void cuSub_internal_ftd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            tor10_double *_Rin = (tor10_double*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_ftf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            tor10_float *_Rin = (tor10_float*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_ftu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_ftu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_fti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_fti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_float *_Lin = (tor10_float*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }



        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const tor10_int64 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const tor10_int64 val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const tor10_int64 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_i64tcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }

        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const tor10_int64 *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const tor10_int64 val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const tor10_int64 *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_i64tcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }


        void cuSub_internal_i64td(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            tor10_double *_Rin = (tor10_double*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_i64tf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            tor10_float *_Rin = (tor10_float*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_i64ti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int64 *_out = (tor10_int64*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_i64tu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int64 *_out = (tor10_int64*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_i64ti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int64 *_out = (tor10_int64*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_i64tu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int64 *_out = (tor10_int64*)out->Mem;
            tor10_int64 *_Lin = (tor10_int64*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }

        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const tor10_uint64 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const tor10_uint64 val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const tor10_uint64 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_u64tcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
             cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
             tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
             cuDoubleComplex  *_Rin = (cuDoubleComplex*)Rin->Mem;
  
              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;
  
                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }

        }

        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const tor10_uint64 *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const tor10_uint64 val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const tor10_uint64 *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_u64tcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
               cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
               tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
               cuFloatComplex  *_Rin = (cuFloatComplex*)Rin->Mem;
  
                tor10_uint32 NBlocks = len/512;
                if(len%512) NBlocks += 1;
  
                  if(Lin->size()==1){
                      cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                  }else if(Rin->size()==1){
                      cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                  }else{
                      cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                  }

        }
        void cuSub_internal_u64td(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
               tor10_double *_out = (tor10_double*)out->Mem;
               tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
               tor10_double  *_Rin = (tor10_double*)Rin->Mem;
  
                tor10_uint32 NBlocks = len/512;
                if(len%512) NBlocks += 1;
  
                  if(Lin->size()==1){
                      cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                  }else if(Rin->size()==1){
                      cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                  }else{
                      cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                  }
        }
        void cuSub_internal_u64tf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
               tor10_float *_out = (tor10_float*)out->Mem;
               tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
               tor10_float  *_Rin = (tor10_float*)Rin->Mem;
  
                tor10_uint32 NBlocks = len/512;
                if(len%512) NBlocks += 1;
  
                  if(Lin->size()==1){
                      cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                  }else if(Rin->size()==1){
                      cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                  }else{
                      cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                  }
        }
        void cuSub_internal_u64ti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
               tor10_int64 *_out = (tor10_int64*)out->Mem;
               tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
               tor10_int64  *_Rin = (tor10_int64*)Rin->Mem;
  
                tor10_uint32 NBlocks = len/512;
                if(len%512) NBlocks += 1;
  
                  if(Lin->size()==1){
                      cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                  }else if(Rin->size()==1){
                      cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                  }else{
                      cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                  }
        }
        void cuSub_internal_u64tu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_uint64 *_out = (tor10_uint64*)out->Mem;
            tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_u64ti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_uint64 *_out = (tor10_uint64*)out->Mem;
            tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }
        void cuSub_internal_u64tu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_uint64 *_out = (tor10_uint64*)out->Mem;
            tor10_uint64 *_Lin = (tor10_uint64*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }




        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const tor10_int32 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const tor10_int32 val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const tor10_int32 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_i32tcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
              cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
              tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
              cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;
  
              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;
  
                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }


        }

        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const tor10_int32 *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const tor10_int32 val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const tor10_int32 *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_i32tcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }
        void cuSub_internal_i32td(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_double *_out = (tor10_double*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            tor10_double *_Rin = (tor10_double*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_i32tf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_float *_out = (tor10_float*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            tor10_float *_Rin = (tor10_float*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }
        void cuSub_internal_i32ti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int64 *_out = (tor10_int64*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }



        }
        void cuSub_internal_i32tu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_uint64 *_out = (tor10_uint64*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }
        void cuSub_internal_i32ti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int32 *_out = (tor10_int32*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }
        void cuSub_internal_i32tu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_int32 *_out = (tor10_int32*)out->Mem;
            tor10_int32 *_Lin = (tor10_int32*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }

        }

        __global__ void cuSub_rconst_kernel(cuDoubleComplex *out, const tor10_uint32 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuDoubleComplex *out, const tor10_uint32 val, const tor10_uint64 Nelem, const cuDoubleComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuDoubleComplex *out, const tor10_uint32 *ptr, const tor10_uint64 Nelem, const cuDoubleComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsub(make_cuDoubleComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_u32tcd(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            cuDoubleComplex *_out = (cuDoubleComplex*)out->Mem;
            tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
            cuDoubleComplex *_Rin = (cuDoubleComplex*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }


        }

        __global__ void cuSub_rconst_kernel(cuFloatComplex *out, const tor10_uint32 *ptr, const tor10_uint64 Nelem, const cuFloatComplex val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val);
            }
            __syncthreads();
        }
        __global__ void cuSub_lconst_kernel(cuFloatComplex *out, const tor10_uint32 val, const tor10_uint64 Nelem, const cuFloatComplex *ptr){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(val,0),ptr[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        __global__ void cuSub_tn_kernel(cuFloatComplex *out, const tor10_uint32 *ptr, const tor10_uint64 Nelem, const cuFloatComplex *val){
            if(blockIdx.x*blockDim.x + threadIdx.x < Nelem){
                out[blockIdx.x*blockDim.x + threadIdx.x] = cuCsubf(make_cuFloatComplex(ptr[blockIdx.x*blockDim.x + threadIdx.x],0),val[blockIdx.x*blockDim.x + threadIdx.x]);
            }
            __syncthreads();
        }
        void cuSub_internal_u32tcf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
             cuFloatComplex *_out = (cuFloatComplex*)out->Mem;
              tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
              cuFloatComplex *_Rin = (cuFloatComplex*)Rin->Mem;

              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;

                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }


        }
        void cuSub_internal_u32td(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
              tor10_double *_out = (tor10_double*)out->Mem;
              tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
              tor10_double *_Rin = (tor10_double*)Rin->Mem;

              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;

                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }


        }
        void cuSub_internal_u32tf(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
              tor10_float *_out = (tor10_float*)out->Mem;
              tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
              tor10_float *_Rin = (tor10_float*)Rin->Mem;

              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;

                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }


        }
        void cuSub_internal_u32ti64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
              tor10_int64 *_out = (tor10_int64*)out->Mem;
              tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
              tor10_int64 *_Rin = (tor10_int64*)Rin->Mem;

              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;

                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }


        }
        void cuSub_internal_u32tu64(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
              tor10_uint64 *_out = (tor10_uint64*)out->Mem;
              tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
              tor10_uint64 *_Rin = (tor10_uint64*)Rin->Mem;

              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;

                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }

        }
        void cuSub_internal_u32ti32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
              tor10_int32 *_out = (tor10_int32*)out->Mem;
              tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
              tor10_int32 *_Rin = (tor10_int32*)Rin->Mem;

              tor10_uint32 NBlocks = len/512;
              if(len%512) NBlocks += 1;

                if(Lin->size()==1){
                    cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
                }else if(Rin->size()==1){
                    cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
                }else{
                    cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
                }

        }
        void cuSub_internal_u32tu32(boost::intrusive_ptr<Storage_base> & out, boost::intrusive_ptr<Storage_base> & Lin, boost::intrusive_ptr<Storage_base> & Rin, const unsigned long long &len){
            tor10_uint32 *_out = (tor10_uint32*)out->Mem;
            tor10_uint32 *_Lin = (tor10_uint32*)Lin->Mem;
            tor10_uint32 *_Rin = (tor10_uint32*)Rin->Mem;

            tor10_uint32 NBlocks = len/512;
            if(len%512) NBlocks += 1;

              if(Lin->size()==1){
                  cuSub_lconst_kernel<<<NBlocks,512>>>(_out,_Lin[0],len,_Rin);
              }else if(Rin->size()==1){
                  cuSub_rconst_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin[0]);
              }else{
                  cuSub_tn_kernel<<<NBlocks,512>>>(_out,_Lin,len,_Rin);
              }
        }





    }//namespace linalg_internal
}//namespace tor10


