#ifndef _H_CyTensor_
#define _H_CyTensor_

#include "Type.hpp"
#include "cytnx_error.hpp"
#include "Storage.hpp"
#include "Device.hpp"
#include "Tensor.hpp"
#include "utils/utils.hpp"
#include "intrusive_ptr_base.hpp"
#include <iostream>
#include <vector>
#include <map>
#include <utility>
#include <initializer_list>
#include <algorithm>
#include "Symmetry.hpp"
#include "Bond.hpp"

//namespace cytnx{
namespace cytnx_extension{ 
    using namespace cytnx;
    /// @cond 
    class CyTensorType_class{
        public:
            enum : int{
                Void=-99,
                Dense=0,
                Sparse=1,
            };
            std::string getname(const int &ut_type);
    };
    extern CyTensorType_class UTenType;
    /// @endcond

    /// @cond
    //class DenseCyTensor;
    //class SparseCyTensor; 
    class CyTensor_base: public intrusive_ptr_base<CyTensor_base>{
        protected:

            std::vector< Bond > _bonds;
            std::vector<cytnx_int64> _labels;
            bool _is_braket_form;
            bool _is_tag;
            cytnx_int64 _Rowrank;
            bool _is_diag;
            std::string _name;
            int uten_type_id; //the unitensor type id.

            bool _update_braket(){
                if(_bonds.size()==0) return false;

                if(this->_bonds[0].type()!= bondType::BD_REG){
                    //check:
                    for(unsigned int i=0;i<this->_bonds.size();i++){
                        if(i<this->_Rowrank){
                            if(this->_bonds[i].type()!=bondType::BD_KET) return false;
                        }else{
                            if(this->_bonds[i].type()!=bondType::BD_BRA) return false;
                        }
                    }
                    return true;
                }else{
                    return false;
                }
            }

        public:
            friend class CyTensor; // allow wrapper to access the private elems
            friend class DenseCyTensor;
            friend class SparseCyTensor;

            CyTensor_base(): _is_tag(false), _name(std::string("")), _is_braket_form(false), _Rowrank(-1), _is_diag(false), uten_type_id(UTenType.Void){};

            //copy&assignment constr., use intrusive_ptr's !!
            CyTensor_base(const CyTensor_base &rhs);
            CyTensor_base& operator=(CyTensor_base &rhs);

            cytnx_uint64 Rowrank() const{return this->_Rowrank;}
            bool is_diag() const{ return this->_is_diag; }
            const bool&     is_braket_form() const{
                return this->_is_braket_form;
            }
            const bool& is_tag() const{
                return this->_is_tag;
            }
            const std::vector<cytnx_int64>& labels() const{ return this->_labels;}
            const std::vector<Bond> &bonds() const {return this->_bonds;}       
            const std::string& name() const { return this->_name;}
            cytnx_uint64  rank() const {return this->_labels.size();}
            void set_name(const std::string &in){ this->_name = in;}
            void set_Rowrank(const cytnx_uint64 &new_Rowrank){
                cytnx_error_msg(new_Rowrank >= this->_labels.size(),"[ERROR] Rowrank cannot exceed the rank of CyTensor.%s","\n");
                this->_Rowrank = new_Rowrank;
            }
            void set_label(const cytnx_uint64 &idx, const cytnx_int64 &new_label){
                cytnx_error_msg(idx>=this->_labels.size(),"[ERROR] index exceed the rank of CyTensor%s","\n");
                //check in:
                bool is_dup =false;
                for(cytnx_uint64 i=0;i<this->_labels.size();i++){
                    if(new_label == this->_labels[i]){is_dup = true; break;}
                }
                cytnx_error_msg(is_dup,"[ERROR] alreay has a label that is the same as the input label%s","\n");
                this->_labels[idx] = new_label;                
            }
            void set_labels(const std::vector<cytnx_int64> &new_labels);
            template<class T>
            T& at(const std::vector<cytnx_uint64> &locator){
                //std::cout << "at " << this->is_blockform()  << std::endl;
                if(this->is_blockform()){
                    // sparse
                    //cytnx_error_msg(this->is_blockform(),"[ERROR] cannot access element using at<T> on a CyTensor with symmetry.\n suggestion: get_block/get_blocks first.%s","\n");
                    //std::cout << "[at, blockform]" << std::endl;
                    T aux;
                    return this->at_for_sparse(locator, aux);

                }else{
                    return this->get_block_().at<T>(locator);
                }

            }
            int uten_type(){
                return this->uten_type_id;
            }
            std::string uten_type_str(){
                return UTenType.getname(this->uten_type_id);
            }

            


            virtual void Init(const std::vector<Bond> &bonds, const std::vector<cytnx_int64> &in_labels={}, const cytnx_int64 &Rowrank=-1,const unsigned int &dtype=Type.Double,const int &device = Device.cpu,const bool &is_diag=false);
            virtual void Init_by_Tensor(const Tensor& in, const cytnx_uint64 &Rowrank);
            virtual std::vector<cytnx_uint64> shape() const;
            virtual bool      is_blockform() const ;
            virtual bool     is_contiguous() const;
            virtual void to_(const int &device);
            virtual boost::intrusive_ptr<CyTensor_base> to(const int &device);
            virtual boost::intrusive_ptr<CyTensor_base> clone() const;
            virtual unsigned int  dtype() const;
            virtual int          device() const;
            virtual std::string      dtype_str() const;
            virtual std::string     device_str() const;
            virtual boost::intrusive_ptr<CyTensor_base> permute(const std::vector<cytnx_int64> &mapper,const cytnx_int64 &Rowrank=-1, const bool &by_label=false);
            virtual void permute_(const std::vector<cytnx_int64> &mapper, const cytnx_int64 &Rowrank=-1, const bool &by_label=false);
            virtual boost::intrusive_ptr<CyTensor_base> contiguous_();
            virtual boost::intrusive_ptr<CyTensor_base> contiguous();            
            virtual void print_diagram(const bool &bond_info=false);

            virtual Tensor get_block(const cytnx_uint64 &idx=0) const; // return a copy of block
            virtual Tensor get_block(const std::vector<cytnx_int64> &qnum) const; //return a copy of block

            virtual const Tensor& get_block_(const cytnx_uint64 &idx=0) const; // return a share view of block, this only work for non-symm tensor.
            virtual const Tensor& get_block_(const std::vector<cytnx_int64> &qnum) const; //return a copy of block
            virtual Tensor& get_block_(const cytnx_uint64 &idx=0); // return a share view of block, this only work for non-symm tensor.
            virtual Tensor& get_block_(const std::vector<cytnx_int64> &qnum); //return a copy of block


            virtual std::vector<Tensor> get_blocks() const;
            virtual const std::vector<Tensor>& get_blocks_() const;
            virtual std::vector<Tensor>& get_blocks_();

            virtual void put_block(const Tensor &in, const cytnx_uint64 &idx=0);
            virtual void put_block_(const Tensor &in, const cytnx_uint64 &idx=0);
            virtual void put_block(const Tensor &in, const std::vector<cytnx_int64> &qnum);
            virtual void put_block_(const Tensor &in, const std::vector<cytnx_int64> &qnum);

            // this will only work on non-symm tensor (DenseCyTensor)
            virtual boost::intrusive_ptr<CyTensor_base> get(const std::vector<Accessor> &accessors);
            // this will only work on non-symm tensor (DenseCyTensor)
            virtual void set(const std::vector<Accessor> &accessors, const Tensor &rhs);
            virtual void reshape_(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0);
            virtual boost::intrusive_ptr<CyTensor_base> reshape(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0);
            virtual boost::intrusive_ptr<CyTensor_base> to_dense();
            virtual void to_dense_();
            virtual void combineBonds(const std::vector<cytnx_int64> &indicators, const bool &permute_back=false, const bool &by_label=true);
            virtual boost::intrusive_ptr<CyTensor_base> contract(const boost::intrusive_ptr<CyTensor_base> &rhs);
            virtual std::vector<Bond> getTotalQnums(const bool &physical=false);          
            virtual boost::intrusive_ptr<CyTensor_base> Conj();
            virtual void Trace_(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false);
            virtual boost::intrusive_ptr<CyTensor_base> Trace(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false);
            virtual void Conj_();

            // this a workaround, as virtual function cannot template.
            virtual cytnx_complex128& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_complex128 &aux);
            virtual cytnx_complex64& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_complex64 &aux);
            virtual cytnx_double& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_double &aux);
            virtual cytnx_float& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_float &aux);


            virtual ~CyTensor_base(){};
    };
    /// @endcond

    //======================================================================
    /// @cond
    class DenseCyTensor: public CyTensor_base{
        protected:
            Tensor _block;
            DenseCyTensor* clone_meta() const{
                DenseCyTensor* tmp = new DenseCyTensor();
                tmp->_bonds = vec_clone(this->_bonds);
                tmp->_labels = this->_labels;
                tmp->_is_braket_form = this->_is_braket_form;
                tmp->_Rowrank = this->_Rowrank;
                tmp->_is_diag = this->_is_diag;
                tmp->_name = this->_name;
                tmp->_is_tag = this->_is_tag; 
                return tmp;
            }
        public:
            DenseCyTensor(){this->uten_type_id = UTenType.Dense;};
            friend class CyTensor; // allow wrapper to access the private elems
            // virtual functions
            void Init(const std::vector<Bond> &bonds, const std::vector<cytnx_int64> &in_labels={}, const cytnx_int64 &Rowrank=-1, const unsigned int &dtype=Type.Double,const int &device = Device.cpu, const bool &is_diag=false);
            // this only work for non-symm tensor
            void Init_by_Tensor(const Tensor& in_tensor, const cytnx_uint64 &Rowrank);
            std::vector<cytnx_uint64> shape() const{ 
                if(this->_is_diag){
                    std::vector<cytnx_uint64> shape = this->_block.shape();
                    shape.push_back(shape[0]);
                    return shape;
                }else{
                    return this->_block.shape();
                }
            }
            bool is_blockform() const{ return false;}
            void to_(const int &device){
                this->_block.to_(device);
            }
            boost::intrusive_ptr<CyTensor_base> to(const int &device){
                if(this->device() == device){
                    return this;
                }else{
                    boost::intrusive_ptr<CyTensor_base> out = this->clone();
                    out->to_(device);
                    return out;   
                } 
            }
            boost::intrusive_ptr<CyTensor_base> clone() const{
                DenseCyTensor* tmp = this->clone_meta();
                tmp->_block = this->_block.clone();
                boost::intrusive_ptr<CyTensor_base> out(tmp);
                return out;
            };
            bool     is_contiguous() const{return this->_block.is_contiguous();}
            unsigned int  dtype() const{return this->_block.dtype();}
            int          device() const{return this->_block.device();}
            std::string      dtype_str() const{ return Type.getname(this->_block.dtype());}
            std::string     device_str() const{ return Device.getname(this->_block.device());}
            boost::intrusive_ptr<CyTensor_base> permute(const std::vector<cytnx_int64> &mapper,const cytnx_int64 &Rowrank=-1,const bool &by_label=false);
            void permute_(const std::vector<cytnx_int64> &mapper, const cytnx_int64 &Rowrank=-1, const bool &by_label=false);
            boost::intrusive_ptr<CyTensor_base> contiguous_(){this->_block.contiguous_(); return boost::intrusive_ptr<CyTensor_base>(this);}
            boost::intrusive_ptr<CyTensor_base> contiguous(){
                // if contiguous then return self! 
                if(this->is_contiguous()){
                    boost::intrusive_ptr<CyTensor_base> out(this);
                    return out;
                }else{
                    DenseCyTensor* tmp = this->clone_meta();
                    tmp->_block = this->_block.contiguous();
                    boost::intrusive_ptr<CyTensor_base> out(tmp);
                    return out;
                }
            }
            void print_diagram(const bool &bond_info=false);         
            Tensor get_block(const cytnx_uint64 &idx=0) const{ return this->_block.clone(); }

            Tensor get_block(const std::vector<cytnx_int64> &qnum) const{cytnx_error_msg(true,"[ERROR][DenseCyTensor] try to get_block() using qnum on a non-symmetry CyTensor%s","\n"); return Tensor();}
            // return a share view of block, this only work for non-symm tensor.
            const Tensor& get_block_(const std::vector<cytnx_int64> &qnum) const{cytnx_error_msg(true,"[ERROR][DenseCyTensor] try to get_block_() using qnum on a non-symmetry CyTensor%s","\n"); return this->_block;}
            Tensor& get_block_(const std::vector<cytnx_int64> &qnum){cytnx_error_msg(true,"[ERROR][DenseCyTensor] try to get_block_() using qnum on a non-symmetry CyTensor%s","\n"); return this->_block;}

            // return a share view of block, this only work for non-symm tensor.
            Tensor& get_block_(const cytnx_uint64 &idx=0){
                return this->_block;
            }
            // return a share view of block, this only work for non-symm tensor.
            const Tensor& get_block_(const cytnx_uint64 &idx=0) const{
                return this->_block;
            }


            std::vector<Tensor> get_blocks() const {
                std::vector<Tensor> out;
                out.push_back(this->_block.clone());
                return out; // this will not share memory!!
            }
            const std::vector<Tensor>& get_blocks_() const {
                std::vector<Tensor> out;
                out.push_back(this->_block);
                return out; // this will not share memory!!
            }
            std::vector<Tensor>& get_blocks_(){
                std::vector<Tensor> out;
                out.push_back(this->_block);
                return out; // this will not share memory!!
            }

            void put_block(const Tensor &in, const cytnx_uint64 &idx=0){
                if(this->is_diag()){
                    cytnx_error_msg(in.shape() != this->_block.shape(),"[ERROR][DenseCyTensor] put_block, the input tensor shape does not match.%s","\n");
                    this->_block = in.clone();
                }else{
                    cytnx_error_msg(in.shape() != this->shape(),"[ERROR][DenseCyTensor] put_block, the input tensor shape does not match.%s","\n");
                    this->_block = in.clone();
                }
            }
            // share view of the block
            void put_block_(const Tensor &in, const cytnx_uint64 &idx=0){
                if(this->is_diag()){
                    cytnx_error_msg(in.shape() != this->_block.shape(),"[ERROR][DenseCyTensor] put_block, the input tensor shape does not match.%s","\n");
                    this->_block = in;
                }else{
                    cytnx_error_msg(in.shape() != this->shape(),"[ERROR][DenseCyTensor] put_block, the input tensor shape does not match.%s","\n");
                    this->_block = in;
                }
            }

            void put_block(const Tensor &in, const std::vector<cytnx_int64> &qnum){
                cytnx_error_msg(true,"[ERROR][DenseCyTensor] try to put_block using qnum on a non-symmetry CyTensor%s","\n");
            }
            void put_block_(const Tensor &in, const std::vector<cytnx_int64> &qnum){
                cytnx_error_msg(true,"[ERROR][DenseCyTensor] try to put_block using qnum on a non-symmetry CyTensor%s","\n");
            }
            // this will only work on non-symm tensor (DenseCyTensor)
            boost::intrusive_ptr<CyTensor_base> get(const std::vector<Accessor> &accessors){
                boost::intrusive_ptr<CyTensor_base> out(new DenseCyTensor());
                out->Init_by_Tensor(this->_block.get(accessors),0); //wrapping around. 
                return out;
            }
            // this will only work on non-symm tensor (DenseCyTensor)
            void set(const std::vector<Accessor> &accessors, const Tensor &rhs){
                this->_block.set(accessors,rhs);
            }
            void reshape_(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0){
                cytnx_error_msg(this->is_tag(),"[ERROR] cannot reshape a tagged CyTensor. suggestion: use untag() first.%s","\n");
                cytnx_error_msg(Rowrank > new_shape.size(), "[ERROR] Rowrank cannot larger than the rank of reshaped CyTensor.%s","\n");
                this->_block.reshape_(new_shape);
                this->Init_by_Tensor(this->_block,Rowrank);
            }
            boost::intrusive_ptr<CyTensor_base> reshape(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0){
                cytnx_error_msg(this->is_tag(),"[ERROR] cannot reshape a tagged CyTensor. suggestion: use untag() first.%s","\n");
                cytnx_error_msg(Rowrank > new_shape.size(), "[ERROR] Rowrank cannot larger than the rank of reshaped CyTensor.%s","\n");
                boost::intrusive_ptr<CyTensor_base> out(new DenseCyTensor());
                out->Init_by_Tensor(this->_block.reshape(new_shape),Rowrank);
                return out;
            }
            boost::intrusive_ptr<CyTensor_base> to_dense();
            void to_dense_();

            void combineBonds(const std::vector<cytnx_int64> &indicators, const bool &permute_back=true, const bool &by_label=true);
            boost::intrusive_ptr<CyTensor_base> contract(const boost::intrusive_ptr<CyTensor_base> &rhs);
            std::vector<Bond> getTotalQnums(const bool &physical=false){
                cytnx_error_msg(true,"[ERROR][DenseCyTensor] %s","getTotalQnums can only operate on CyTensor with symmetry.\n");
                return std::vector<Bond>();
            }        
            ~DenseCyTensor(){};


            void Conj_(){
                this->_block.Conj_();
            };
            
            boost::intrusive_ptr<CyTensor_base> Conj(){
                boost::intrusive_ptr<CyTensor_base> out = this->clone();
                out->Conj_();
                return out;
            }
            
            void Trace_(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false);
            boost::intrusive_ptr<CyTensor_base> Trace(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false){
                boost::intrusive_ptr<CyTensor_base> out = this->clone();
                out->Trace_(a,b,by_label);
                return out;
            }
            cytnx_complex128& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_complex128 &aux){
                cytnx_error_msg(true,"[ERROR][Internal] This shouldn't be called by DenseCyTensor, something wrong.%s","\n");
                //return cytnx_complex128(0,0);
            }
            cytnx_complex64& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_complex64 &aux){
                cytnx_error_msg(true,"[ERROR][Internal] This shouldn't be called by DenseCyTensor, something wrong.%s","\n");
                //return cytnx_complex64(0,0);
            }
            cytnx_double& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_double &aux){
                cytnx_error_msg(true,"[ERROR][Internal] This shouldn't be called by DenseCyTensor, something wrong.%s","\n");
                //return 0;
            }
            cytnx_float& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_float &aux){
                cytnx_error_msg(true,"[ERROR][Internal] This shouldn't be called by DenseCyTensor, something wrong.%s","\n");
                //return 0;
            }

            // end virtual function              

            

    };
    /// @endcond


    //======================================================================
    /// @cond
    class SparseCyTensor: public CyTensor_base{
        protected:
            std::vector<Tensor> _blocks;
            std::vector<cytnx_uint64> _mapper;
            std::vector<cytnx_uint64> _inv_mapper;

            cytnx_uint64 _inner_Rowrank;
            std::vector<std::vector<cytnx_int64> > _blockqnums;
            std::vector<std::vector<cytnx_uint64> > _inner2outer_row;
            std::vector<std::vector<cytnx_uint64> > _inner2outer_col;
            std::map<cytnx_uint64,std::pair<cytnx_uint64,cytnx_uint64> > _outer2inner_row;
            std::map<cytnx_uint64, std::pair<cytnx_uint64,cytnx_uint64> > _outer2inner_col;
            

            bool _contiguous;
            void set_meta(SparseCyTensor *tmp, const bool &inner, const bool &outer)const{
                //outer meta
                if(outer){
                    tmp->_bonds = vec_clone(this->_bonds);
                    tmp->_labels = this->_labels;
                    tmp->_is_braket_form = this->_is_braket_form;
                    tmp->_Rowrank = this->_Rowrank;
                    tmp->_name = this->_name;
                }
                //comm meta
                tmp->_mapper = this->_mapper;
                tmp->_inv_mapper = this->_inv_mapper;
                tmp->_contiguous = this->_contiguous;

                //inner meta    
                if(inner){            
                    tmp->_inner_Rowrank = this->_inner_Rowrank;
                    tmp->_inner2outer_row = this->_inner2outer_row;
                    tmp->_inner2outer_col = this->_inner2outer_col;
                    tmp->_outer2inner_row = this->_outer2inner_row;
                    tmp->_outer2inner_col = this->_outer2inner_col;
                    tmp->_blockqnums = this->_blockqnums;
                }

            }
            SparseCyTensor* clone_meta(const bool &inner, const bool &outer) const{
                SparseCyTensor* tmp = new SparseCyTensor();
                this->set_meta(tmp,inner,outer);
                return tmp;
            };
        
        public:
            friend class CyTensor; // allow wrapper to access the private elems
            SparseCyTensor(){
                this->uten_type_id = UTenType.Sparse;
                this->_is_tag = true; 
            };

            // virtual functions
            void Init(const std::vector<Bond> &bonds, const std::vector<cytnx_int64> &in_labels={}, const cytnx_int64 &Rowrank=-1, const unsigned int &dtype=Type.Double,const int &device = Device.cpu, const bool &is_diag=false);
            void Init_by_Tensor(const Tensor& in_tensor, const cytnx_uint64 &Rowrank){
                cytnx_error_msg(true,"[ERROR][SparseCyTensor] cannot use Init_by_tensor() on a SparseCyTensor.%s","\n");
            }
            std::vector<cytnx_uint64> shape() const{ 
                std::vector<cytnx_uint64> out(this->_bonds.size());
                for(cytnx_uint64 i=0;i<out.size();i++){
                    out[i] = this->_bonds[i].dim();
                }
                return out;
            }
            bool is_blockform() const{return true;}
            void to_(const int &device){
                for(cytnx_uint64 i=0;i<this->_blocks.size();i++){
                    this->_blocks[i].to_(device);
                }
            };
            boost::intrusive_ptr<CyTensor_base> to(const int &device){
                if(this->device() == device){
                    return this;
                }else{
                    boost::intrusive_ptr<CyTensor_base> out = this->clone();
                    out->to_(device);
                    return out;
                }
            };
            boost::intrusive_ptr<CyTensor_base> clone() const{
                SparseCyTensor* tmp = this->clone_meta(true,true);
                tmp->_blocks = vec_clone(this->_blocks);
                boost::intrusive_ptr<CyTensor_base> out(tmp);
                return out;
            };
            bool     is_contiguous() const{
                return this->_contiguous;
            };
            unsigned int  dtype() const{
                #ifdef UNI_DEBUG
                cytnx_error_msg(this->_blocks.size()==0,"[ERROR][internal] empty blocks for blockform.%s","\n");
                #endif
                return this->_blocks[0].dtype();
            };
            int          device() const{
                #ifdef UNI_DEBUG
                cytnx_error_msg(this->_blocks.size()==0,"[ERROR][internal] empty blocks for blockform.%s","\n");
                #endif
                return this->_blocks[0].device();
            };
            std::string      dtype_str() const{
                #ifdef UNI_DEBUG
                cytnx_error_msg(this->_blocks.size()==0,"[ERROR][internal] empty blocks for blockform.%s","\n");
                #endif
                return this->_blocks[0].dtype_str();
            };
            std::string     device_str() const{
                #ifdef UNI_DEBUG
                cytnx_error_msg(this->_blocks.size()==0,"[ERROR][internal] empty blocks for blockform.%s","\n");
                #endif
                return this->_blocks[0].device_str();
            };
            void permute_(const std::vector<cytnx_int64> &mapper, const cytnx_int64 &Rowrank=-1,const bool &by_label=false);
            boost::intrusive_ptr<CyTensor_base> permute(const std::vector<cytnx_int64> &mapper,const cytnx_int64 &Rowrank=-1, const bool &by_label=false){
                boost::intrusive_ptr<CyTensor_base> out = this->clone();
                out->permute_(mapper,Rowrank,by_label);
                return out;
            };
            boost::intrusive_ptr<CyTensor_base> contiguous();
            boost::intrusive_ptr<CyTensor_base> contiguous_(){
                if(!this->_contiguous){
                    boost::intrusive_ptr<CyTensor_base> titr = this->contiguous();
                    SparseCyTensor *tmp = (SparseCyTensor*)titr.get();
                    tmp->set_meta(this,true,true);
                    this->_blocks = tmp->_blocks;
                    
                }
                return boost::intrusive_ptr<CyTensor_base>(this);
                
            }
            void print_diagram(const bool &bond_info=false);

            Tensor get_block(const cytnx_uint64 &idx=0) const{
                cytnx_error_msg(idx>=this->_blocks.size(),"[ERROR][SparseCyTensor] index out of range%s","\n");
                if(this->_contiguous){
                    return this->_blocks[idx].clone();
                }else{
                    cytnx_error_msg(true,"[Developing] get block from a non-contiguous SparseCyTensor is currently not support. Call contiguous()/contiguous_() first.%s","\n");
                    return Tensor();
                }
            };

            Tensor get_block(const std::vector<cytnx_int64> &qnum) const{
                cytnx_error_msg(!this->is_braket_form(),"[ERROR][Un-physical] cannot get the block by qnums when bra-ket/in-out bonds mismatch the row/col space.\n permute to the correct physical space first, then get block.%s","\n");
                //std::cout << "get_block" <<std::endl;
                if(this->_contiguous){
                    //std::cout << "contiguous" << std::endl;
                    //get dtype from qnum:
                    cytnx_int64 idx=-1;
                    for(int i=0;i<this->_blockqnums.size();i++){
                        for(int j=0;j<this->_blockqnums[i].size();j++)
                            std::cout << this->_blockqnums[i][j]<< " ";
                        std::cout << std::endl;
                        if(qnum==this->_blockqnums[i]){idx=i; break;}
                    }
                    cytnx_error_msg(idx<0,"[ERROR][SparseCyTensor] no block with [qnum] exists in the current CyTensor.%s","\n");
                    return this->get_block(idx);
                }else{
                    cytnx_error_msg(true,"[Developing] get block from a non-contiguous SparseCyTensor is currently not support. Call contiguous()/contiguous_() first.%s","\n");
                    return Tensor();
                }
                return Tensor();
            };

            // return a share view of block, this only work for symm tensor in contiguous form.
            Tensor& get_block_(const cytnx_uint64 &idx=0){
                cytnx_error_msg(this->is_contiguous()==false,"[ERROR][SparseCyTensor] cannot use get_block_() on non-contiguous CyTensor with symmetry.\n suggest options: \n  1) Call contiguous_()/contiguous() first, then call get_blocks_()\n  2) Try get_block()/get_blocks()%s","\n");
                
                cytnx_error_msg(idx >= this->_blocks.size(),"[ERROR][SparseCyTensor] index exceed the number of blocks.%s","\n");

                return this->_blocks[idx];
            }
            const Tensor& get_block_(const cytnx_uint64 &idx=0) const{
                cytnx_error_msg(this->is_contiguous()==false,"[ERROR][SparseCyTensor] cannot use get_block_() on non-contiguous CyTensor with symmetry.\n suggest options: \n  1) Call contiguous_()/contiguous() first, then call get_blocks_()\n  2) Try get_block()/get_blocks()%s","\n");
                
                cytnx_error_msg(idx >= this->_blocks.size(),"[ERROR][SparseCyTensor] index exceed the number of blocks.%s","\n");

                return this->_blocks[idx];
            }

            Tensor& get_block_(const std::vector<cytnx_int64> &qnum){
                cytnx_error_msg(this->is_contiguous()==false,"[ERROR][SparseCyTensor] cannot use get_block_() on non-contiguous CyTensor with symmetry.\n suggest options: \n  1) Call contiguous_()/contiguous() first, then call get_blocks_()\n  2) Try get_block()/get_blocks()%s","\n");
                
                //get dtype from qnum:
                cytnx_int64 idx=-1;
                for(int i=0;i<this->_blockqnums.size();i++){
                    if(qnum==this->_blockqnums[i]){idx=i; break;}
                }
                cytnx_error_msg(idx<0,"[ERROR][SparseCyTensor] no block with [qnum] exists in the current CyTensor.%s","\n");
                return this->get_block_(idx);
                //cytnx_error_msg(true,"[Developing]%s","\n");
            }
            const Tensor& get_block_(const std::vector<cytnx_int64> &qnum) const{
                cytnx_error_msg(this->is_contiguous()==false,"[ERROR][SparseCyTensor] cannot use get_block_() on non-contiguous CyTensor with symmetry.\n suggest options: \n  1) Call contiguous_()/contiguous() first, then call get_blocks_()\n  2) Try get_block()/get_blocks()%s","\n");
                
                //get dtype from qnum:
                cytnx_int64 idx=-1;
                for(int i=0;i<this->_blockqnums.size();i++){
                    if(qnum==this->_blockqnums[i]){idx=i; break;}
                }
                cytnx_error_msg(idx<0,"[ERROR][SparseCyTensor] no block with [qnum] exists in the current CyTensor.%s","\n");
                return this->get_block_(idx);
            }

            std::vector<Tensor> get_blocks() const {
                if(this->_contiguous){
                    return vec_clone(this->_blocks);
                }else{
                    //cytnx_error_msg(true,"[Developing]%s","\n");
                    boost::intrusive_ptr<CyTensor_base> tmp = this->clone();
                    tmp->contiguous_(); 
                    SparseCyTensor *ttmp = (SparseCyTensor*)tmp.get();
                    return ttmp->_blocks;
                }
            };

            const std::vector<Tensor>& get_blocks_() const {
                //cout << "[call this]" << endl;
                if(this->_contiguous){
                    return this->_blocks;
                }else{
                    //cytnx_error_msg(true,"[Developing]%s","\n");
                    cytnx_error_msg(true,"[ERROR][SparseCyTensor] cannot call get_blocks_() with a non-contiguous CyTensor. \ntry: \n1) get_blocks()\n2) call contiguous/contiguous_() first, then get_blocks_()%s","\n");
                    return this->_blocks;
                }
            };
            std::vector<Tensor>& get_blocks_(){
                //cout << "[call this]" << endl;
                if(this->_contiguous){
                    return this->_blocks;
                }else{
                    cytnx_error_msg(true,"[ERROR][SparseCyTensor] cannot call get_blocks_() with a non-contiguous CyTensor. \ntry: \n1) get_blocks()\n2) call contiguous/contiguous_() first, then get_blocks_()%s","\n");
                    return this->_blocks;
                }
            };


            void put_block(const Tensor &in,const cytnx_uint64 &idx=0){
                cytnx_error_msg(idx>=this->_blocks.size(),"[ERROR][SparseCyTensor] index out of range%s","\n");
                if(this->_contiguous){
                    cytnx_error_msg(in.shape()!=this->_blocks[idx].shape(),"[ERROR][SparseCyTensor] the shape of input tensor does not match the shape of block @ idx=%d\n",idx);
                    this->_blocks[idx] = in.clone();
                }else{
                    cytnx_error_msg(true,"[Developing]%s","\n");
                }
            };
            void put_block_(const Tensor &in,const cytnx_uint64 &idx=0){
                cytnx_error_msg(this->is_contiguous()==false,"[ERROR][SparseCyTensor] cannot use put_block_() on non-contiguous CyTensor with symmetry.\n suggest options: \n  1) Call contiguous_()/contiguous() first, then call put_blocks_()\n  2) Try put_block()/put_blocks()%s","\n");

                cytnx_error_msg(idx>=this->_blocks.size(),"[ERROR][SparseCyTensor] index out of range%s","\n");
                cytnx_error_msg(in.shape()!=this->_blocks[idx].shape(),"[ERROR][SparseCyTensor] the shape of input tensor does not match the shape of block @ idx=%d\n",idx);
                this->_blocks[idx] = in;
            };
            void put_block(const Tensor &in, const std::vector<cytnx_int64> &qnum){
                cytnx_error_msg(true,"[Developing]%s","\n");
            };
            void put_block_(const Tensor &in, const std::vector<cytnx_int64> &qnum){
                cytnx_error_msg(true,"[Developing]%s","\n");
            };

            // this will only work on non-symm tensor (DenseCyTensor)
            boost::intrusive_ptr<CyTensor_base> get(const std::vector<Accessor> &accessors){
                cytnx_error_msg(true,"[ERROR][SparseCyTensor][get] cannot use get on a CyTensor with Symmetry.\n suggestion: try get_block()/get_blocks() first.%s","\n");
                return nullptr;  
            }
            // this will only work on non-symm tensor (DenseCyTensor)
            void set(const std::vector<Accessor> &accessors, const Tensor &rhs){
                cytnx_error_msg(true,"[ERROR][SparseCyTensor][set] cannot use set on a CyTensor with Symmetry.\n suggestion: try get_block()/get_blocks() first.%s","\n");
            }
            void reshape_(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0){
                cytnx_error_msg(true,"[ERROR] cannot reshape a CyTensor with symmetry.%s","\n");
            }
            boost::intrusive_ptr<CyTensor_base> reshape(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0){
                cytnx_error_msg(true,"[ERROR] cannot reshape a CyTensor with symmetry.%s","\n");
                return nullptr;
            }
            boost::intrusive_ptr<CyTensor_base> to_dense(){
                cytnx_error_msg(true,"[ERROR] cannot to_dense a CyTensor with symmetry.%s","\n");
                return nullptr;
            }
            void to_dense_(){
                cytnx_error_msg(true,"[ERROR] cannot to_dense_ a CyTensor with symmetry.%s","\n");
            }
            void combineBonds(const std::vector<cytnx_int64> &indicators, const bool &permute_back=true, const bool &by_label=true){
                cytnx_error_msg(true,"[Developing]%s","\n");
            };
            boost::intrusive_ptr<CyTensor_base> contract(const boost::intrusive_ptr<CyTensor_base> &rhs){
                cytnx_error_msg(true,"[Developing]%s","\n");
                return nullptr;
            };
            std::vector<Bond> getTotalQnums(const bool &physical=false);
            ~SparseCyTensor(){};


            boost::intrusive_ptr<CyTensor_base> Conj(){
                cytnx_error_msg(true,"[Developing]%s","\n");
                return nullptr;
            }

            void Conj_(){
                //this->_block.Conj_();
                cytnx_error_msg(true,"[Developing]%s","\n");
            };
            boost::intrusive_ptr<CyTensor_base> Trace(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false) const{
                cytnx_error_msg(true,"[Developing]%s","\n");
                return nullptr;
            };
            void Trace_(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false){
                cytnx_error_msg(true,"[Developing]%s","\n");
                //return nullptr;
            }

            cytnx_complex128& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_complex128 &aux);
            cytnx_complex64& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_complex64 &aux);
            cytnx_double& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_double &aux);
            cytnx_float& at_for_sparse(const std::vector<cytnx_uint64> &locator, const cytnx_float &aux);


            // end virtual func


    };
    /// @endcond

    //======================================================================

    ///@brief An Enhanced tensor specifically designed for physical Tensor network simulation 
    class CyTensor{

        public:

            ///@cond
            boost::intrusive_ptr<CyTensor_base> _impl;
            CyTensor(): _impl(new CyTensor_base()){};
            CyTensor(const CyTensor &rhs){
                this->_impl = rhs._impl;
            }            
            CyTensor& operator=(const CyTensor &rhs){
                this->_impl = rhs._impl;
                return *this;
            }
            ///@endcond

            //@{
            /**
            @brief Initialize a CyTensor with cytnx::Tensor. 
            @param in_tensor a cytnx::Tensor
            @param Rowrank the Rowrank of the outcome CyTensor.
    
            [Note] 
                1. The constructed CyTensor will have same rank as the input Tensor, with default labels, and a shared view (shared instance) of interal block as the input Tensor. 
                2. The constructed CyTensor is always untagged. 
            

            */
            CyTensor(const Tensor &in_tensor, const cytnx_uint64 &Rowrank): _impl(new CyTensor_base()){
                this->Init(in_tensor,Rowrank);
            }
            void Init(const Tensor &in_tensor, const cytnx_uint64 &Rowrank){
               boost::intrusive_ptr<CyTensor_base> out(new DenseCyTensor());
               out->Init_by_Tensor(in_tensor, Rowrank);
               this->_impl = out;
            }
            //@}


            //@{
            /**
            @brief Initialize a CyTensor. 
            @param bonds the bond list. when init, each bond will be copy( not a shared view of bond object with input bond) 
            @param in_labels the labels for each rank(bond)
            @param Rowrank the rank of physical row space.
            @param dtype the dtype of the CyTensor. It can be any type defined in cytnx::Type.
            @param device the device that the CyTensor is put on. It can be any device defined in cytnx::Device.
            @param is_diag if the constructed CyTensor is a diagonal CyTensor. 
                This can only be assigned true when the CyTensor is square, untagged and rank-2 CyTensor. 
    
            [Note] 
                1. the bonds cannot contain simutaneously untagged bond(s) and tagged bond(s)
                2. If the bonds are with symmetry (qnums), the symmetry types should be the same across all the bonds.
          
            */
            CyTensor(const std::vector<Bond> &bonds, const std::vector<cytnx_int64> &in_labels={}, const cytnx_int64 &Rowrank=-1, const unsigned int &dtype=Type.Double, const int &device = Device.cpu, const bool &is_diag=false): _impl(new CyTensor_base()){
                this->Init(bonds,in_labels,Rowrank,dtype,device,is_diag);
            }
            void Init(const std::vector<Bond> &bonds, const std::vector<cytnx_int64> &in_labels={}, const cytnx_int64 &Rowrank=-1, const unsigned int &dtype=Type.Double, const int &device = Device.cpu, const bool &is_diag=false){

                // checking type:
                bool is_sym = false;
                for(cytnx_uint64 i=0;i<bonds.size();i++){
                    //check 
                    if(bonds[i].syms().size() != 0) is_sym = true;
                    else cytnx_error_msg(is_sym,"[ERROR] cannot have bonds with mixing of symmetry and non-symmetry.%s","\n");
                }

                // dynamical dispatch:
                if(is_sym){
                    std::cout << "sym!!" << std::endl;
                    //cytnx_warning_msg(true,"[warning, still developing, some functions will display \"[Developing]\"][SparseCyTensor]%s","\n");
                    boost::intrusive_ptr<CyTensor_base> out(new SparseCyTensor());
                    this->_impl = out;
                }else{   
                    boost::intrusive_ptr<CyTensor_base> out(new DenseCyTensor());
                    this->_impl = out;
                }
                this->_impl->Init(bonds, in_labels, Rowrank, dtype, device, is_diag);
            }
            //@}            

            /**
            @brief set the name of the CyTensor
            @param in the name. It should be a string.

            */
            void set_name(const std::string &in){
                this->_impl->set_name(in);
            }
            /**
            @brief set a new label for bond at the assigned index.
            @param idx the index of the bond.
            @param new_label the new label that is assign to the bond.

            [Note]
                the new assign label cannot be the same as the label of any other bonds in the CyTensor.
                ( cannot have duplicate labels )

            */
            void set_label(const cytnx_uint64 &idx, const cytnx_int64 &new_label){
                this->_impl->set_label(idx,new_label);
            }

            /**
            @brief set new labels for all the bonds.
            @param new_labels the new labels for each bond.

            [Note]
                the new assign labels cannot have duplicate element(s), and should have the same size as the rank of CyTensor.

            */
            void set_labels(const std::vector<cytnx_int64> &new_labels){
                this->_impl->set_labels(new_labels);
            }
            void set_Rowrank(const cytnx_uint64 &new_Rowrank){
                this->_impl->set_Rowrank(new_Rowrank);
            }

            template<class T>
            T& item(){

                cytnx_error_msg(this->is_blockform(),"[ERROR] cannot use item on CyTensor with Symmetry.\n suggestion: use get_block()/get_blocks() first.%s","\n");
                
                DenseCyTensor* tmp = static_cast<DenseCyTensor*>(this->_impl.get());
                return tmp->_block.item<T>();

            }

            cytnx_uint64 rank() const {return this->_impl->rank();}
            cytnx_uint64 Rowrank() const{return this->_impl->Rowrank();}
            unsigned int  dtype() const{ return this->_impl->dtype(); }
            int uten_type() const{ return this->_impl->uten_type();}
            int          device() const{ return this->_impl->device();   }
            std::string name() const { return this->_impl->name();}
            std::string      dtype_str() const{ return this->_impl->dtype_str();}
            std::string     device_str() const{ return this->_impl->device_str();}
            std::string     uten_type_str() const {return this->_impl->uten_type_str();}
            bool     is_contiguous() const{ return this->_impl->is_contiguous();}
            bool is_diag() const{ return this->_impl->is_diag(); }
            bool is_tag() const { return this->_impl->is_tag();}
            const bool&     is_braket_form() const{
                return this->_impl->is_braket_form();
            }
            const std::vector<cytnx_int64>& labels() const{ return this->_impl->labels();}
            const std::vector<Bond> &bonds() const {return this->_impl->bonds();}       
            std::vector<cytnx_uint64> shape() const{return this->_impl->shape();}
            bool      is_blockform() const{ return this->_impl->is_blockform();}

            void to_(const int &device){this->_impl->to_(device);}
            CyTensor to(const int &device) const{ 
                CyTensor out;
                out._impl = this->_impl->to(device);
                return out;
            }
            CyTensor clone() const{
                CyTensor out;
                out._impl = this->_impl->clone();
                return out;
            }
            CyTensor permute(const std::vector<cytnx_int64> &mapper,const cytnx_int64 &Rowrank=-1,const bool &by_label=false){CyTensor out; out._impl = this->_impl->permute(mapper,Rowrank,by_label); return out;}
            void permute_(const std::vector<cytnx_int64> &mapper,const cytnx_int64 &Rowrank=-1,const bool &by_label=false){
                this->_impl->permute_(mapper,Rowrank,by_label);
            }
            CyTensor contiguous(){
                CyTensor out;
                out._impl = this->_impl->contiguous();
                return out;
            }
            void contiguous_(){
                this->_impl = this->_impl->contiguous_();
            }
            void print_diagram(const bool &bond_info=false){
               this->_impl->print_diagram(bond_info);
            }
            
            template<class T>
            T& at(const std::vector<cytnx_uint64> &locator){
                return this->_impl->at<T>(locator);
            }
            // return a clone of block
            Tensor get_block(const cytnx_uint64 &idx=0) const{
                return this->_impl->get_block(idx);
            };
            //================================
            // return a clone of block
            Tensor get_block(const std::vector<cytnx_int64> &qnum) const{
                return this->_impl->get_block(qnum);
            }
            Tensor get_block(const std::initializer_list<cytnx_int64> &qnum) const{
                std::vector<cytnx_int64> tmp = qnum;
                return get_block(tmp);
            }
            //================================
            // this only work for non-symm tensor. return a shared view of block
            const Tensor& get_block_(const cytnx_uint64 &idx=0) const{
                return this->_impl->get_block_(idx);
            }
            //================================
            // this only work for non-symm tensor. return a shared view of block
            Tensor& get_block_(const cytnx_uint64 &idx=0){
                return this->_impl->get_block_(idx);
            }
            //================================
            // this only work for non-symm tensor. return a shared view of block
            Tensor& get_block_(const std::vector<cytnx_int64> &qnum){
                return this->_impl->get_block_(qnum);
            }
            Tensor& get_block_(const std::initializer_list<cytnx_int64> &qnum){
                std::vector<cytnx_int64> tmp = qnum;
                return get_block_(tmp);
            }
            //================================

            // this only work for non-symm tensor. return a shared view of block
            const Tensor& get_block_(const std::vector<cytnx_int64> &qnum) const{
                return this->_impl->get_block_(qnum);
            }
            const Tensor& get_block_(const std::initializer_list<cytnx_int64> &qnum) const{
                std::vector<cytnx_int64> tmp = qnum;
                return this->_impl->get_block_(tmp);
            }
            //================================
            // this return a shared view of blocks for non-symm tensor.
            // for symmetry tensor, it call contiguous first and return a shared view of blocks. [dev]
            std::vector<Tensor> get_blocks() const {
                return this->_impl->get_blocks();
            }
            // this return a shared view of blocks for non-symm tensor.
            // for symmetry tensor, it call contiguous first and return a shared view of blocks. [dev]
            const std::vector<Tensor>& get_blocks_() const {
                return this->_impl->get_blocks_();
            }
            // for symmetry tensor, it call contiguous first and return a shared view of blocks. [dev]
            std::vector<Tensor>& get_blocks_(){
                return this->_impl->get_blocks_();
            }

            // the put block will have shared view with the internal block, i.e. non-clone. 
            void put_block(const Tensor &in,const cytnx_uint64 &idx=0){
                this->_impl->put_block(in,idx);
            }
            // the put block will have shared view with the internal block, i.e. non-clone. 
            void put_block(const Tensor &in, const std::vector<cytnx_int64> &qnum){
                this->_impl->put_block(in,qnum);
            }
            // the put block will have shared view with the internal block, i.e. non-clone. 
            void put_block_(const Tensor &in,const cytnx_uint64 &idx=0){
                this->_impl->put_block_(in,idx);
            }
            // the put block will have shared view with the internal block, i.e. non-clone. 
            void put_block_(const Tensor &in, const std::vector<cytnx_int64> &qnum){
                this->_impl->put_block_(in,qnum);
            }
            CyTensor get(const std::vector<Accessor> &accessors) const{
                CyTensor out;
                out._impl = this->_impl->get(accessors);
                return out;
            }
            void set(const std::vector<Accessor> &accessors, const Tensor &rhs){
                this->_impl->set(accessors, rhs);
            }

            CyTensor reshape(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0){
                CyTensor out;
                out._impl = this->_impl->reshape(new_shape,Rowrank);
                return out;
            }
            void reshape_(const std::vector<cytnx_int64> &new_shape, const cytnx_uint64 &Rowrank=0){
                this->_impl->reshape_(new_shape,Rowrank);
            }
            CyTensor to_dense(){
                CyTensor out;
                out._impl = this->_impl->to_dense();
                return out;
            }            
            void to_dense_(){
                this->_impl->to_dense_();
            }
            void combineBonds(const std::vector<cytnx_int64> &indicators, const bool &permute_back=true, const bool &by_label=true){
                this->_impl->combineBonds(indicators,permute_back,by_label);
            }
            CyTensor contract(const CyTensor &inR) const{
                CyTensor out;
                out._impl = this->_impl->contract(inR._impl);
                return out;
            }
            std::vector<Bond> getTotalQnums(const bool physical=false) const{
                return this->_impl->getTotalQnums(physical);
            }

                        
            //Arithmetic:
            template<class T>
            CyTensor& operator+=(const T &rc);
            template<class T>
            CyTensor& operator-=(const T &rc);
            template<class T>
            CyTensor& operator*=(const T &rc);
            template<class T>
            CyTensor& operator/=(const T &rc);

            template<class T>
            CyTensor Add(const T &rhs){
                return *this + rhs;
            }
            template<class T>
            CyTensor& Add_(const T &rhs){
                return *this += rhs;
            }

            template<class T>
            CyTensor Sub(const T &rhs){
                return *this - rhs;
            }
            template<class T>
            CyTensor& Sub_(const T &rhs){
                return *this -= rhs;
            }

            template<class T>
            CyTensor Mul(const T &rhs){
                return *this * rhs;
            }
            template<class T>
            CyTensor& Mul_(const T &rhs){
                return *this *= rhs;
            }

            template<class T>
            CyTensor Div(const T &rhs){
                return *this / rhs;
            }
            template<class T>
            CyTensor& Div_(const T &rhs){
                return *this /= rhs;
            }

            CyTensor Conj(){
                CyTensor out;
                out._impl = this->_impl->Conj();
                return out;
            }
        
            CyTensor& Conj_(){
                this->_impl->Conj_();
                return *this;
            }



            CyTensor Trace(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false) const{
                CyTensor out;
                out._impl = this->_impl->Trace(a,b,by_label);
                return out;
            }

            CyTensor& Trace_(const cytnx_int64 &a, const cytnx_int64 &b, const bool &by_label=false){
                this->_impl->Trace_(a,b,by_label);
                return *this;
            }


    };//class CyTensor

    ///@cond
    std::ostream& operator<<(std::ostream& os, const CyTensor &in);
    ///@endcond

    /**
    @brief Contract two CyTensor by tracing the ranks with common labels.
    @param inL the Tensor #1
    @param inR the Tensor #2
    @return 
        [CyTensor]

    See also \link cytnx::CyTensor::contract CyTensor.contract \endlink

    */
    CyTensor Contract(const CyTensor &inL, const CyTensor &inR);


}
#endif
