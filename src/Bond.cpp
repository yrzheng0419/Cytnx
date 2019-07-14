#include "Bond.hpp"

using namespace std;
namespace cytnx{

    void Bond_impl::Init(const cytnx_uint64 &dim, const bondType &bd_type, const std::vector<std::vector<cytnx_int64> > &in_qnums,const std::vector<Symmetry> &in_syms){
       
        cytnx_error_msg(dim==0,"%s","[ERROR] Bond_impl cannot have 0 or negative dimension.");
        //check is symmetry:
        if(in_qnums.size()==0){
            cytnx_error_msg(in_syms.size()!=0,"[ERROR] No qnums assigned, but with symmetry provided.%s","\n");
            this->_type = bd_type;
            this->_dim = dim;

        }else{
                

            //cytnx_uint64 Ndim = in_qnums.begin()[0].size();
            cytnx_error_msg(in_qnums.size()!=dim,"%s","[ERROR] invalid qnums. the # of row of qnums list should be identify across each column, and consist with [dim]");
            cytnx_uint64 N_syms = in_qnums[0].size();
            for(cytnx_uint64 i=0;i<in_qnums.size();i++){
                cytnx_error_msg(in_qnums.begin()[i].size() != N_syms,"[ERROR] invalid syms number on index %d. the # of column list should be identify across each row, and consist with [# of symmetries]\n",i);
            }
            
            //cytnx_error_msg(Nsym==0,"%s","[ERROR] pass empty qnums to initialize Bond_impl is invalid.");
            if(in_syms.size()==0){
                this->_syms.clear();
                this->_syms.resize(N_syms);
                for(cytnx_uint64 i=0;i<N_syms;i++){
                    this->_syms[i] = Symmetry::U1();
                }
                
            }else{
                cytnx_error_msg(in_syms.size()!=N_syms,"%s","[ERROR] the number of symmetry should match the # of cols of passed-in qnums.");
                this->_syms = vec_clone(in_syms);
            }
            this->_dim = dim;
            this->_qnums = in_qnums;
            this->_type = bd_type;

            //check qnums match the rule of each symmetry type
            for(cytnx_uint64 d=0;d<in_qnums.size();d++){
                for(cytnx_uint64 i=0;i<N_syms;i++)
                    cytnx_error_msg(!this->_syms[i].check_qnum(this->_qnums[d][i]),"[ERROR] invalid qnums @ index %d with Symmetry: %s\n",d,this->_syms[i].stype_str().c_str());
            }
        }
    }
    
    void Bond_impl::combineBond_(const boost::intrusive_ptr<Bond_impl> &bd_in){
        //check:
        cytnx_error_msg(this->type() != bd_in->type(),"%s\n","[ERROR] cannot combine two Bonds with different types.");
        cytnx_error_msg(this->Nsym() != bd_in->Nsym(),"%s\n","[ERROR] cannot combine two Bonds with differnet symmetry.");
        if(this->Nsym() != 0)
            cytnx_error_msg(this->syms() != bd_in->syms(),"%s\n","[ERROR] cannot combine two Bonds with differnet symmetry.");

        this->_dim *= bd_in->dim(); // update to new dimension
    
        /// handle symmetry
        std::vector<std::vector<cytnx_int64> > new_qnums(this->_dim,std::vector<cytnx_int64>(this->Nsym()));

        #ifdef UNI_OMP
        #pragma omp parallel for schedule(dynamic)
        #endif
        for(cytnx_uint64 d=0;d<this->_dim;d++){
            
            for(cytnx_uint32 i=0;i<this->Nsym();i++){        
                this->_syms[i].combine_rule_(new_qnums[d][i],this->_qnums[cytnx_uint64(d/bd_in->dim())][i],bd_in->qnums()[d%bd_in->dim()][i]);
            }
        }     
                   
        this->_qnums = new_qnums;
    }                    
    /*
    void Bond_impl::Init(const cytnx_uint64 &dim, const std::initializer_list<std::initializer_list<cytnx_int64> > &in_qnums,const std::initializer_list<Symmetry> &in_syms,const bondType &bd_type){


        std::vector< std::vector<cytnx_int64> > in_vec_qnums(in_qnums.size());
        for(cytnx_uint64 i=0;i<in_qnums.size();i++){
            //cytnx_error_msg(in_qnums.begin()[i].size() != Nsym,"%s","[ERROR] invalid qnums. the # of column of qnums list should be identify across each row. ");
            in_vec_qnums[i] = in_qnums.begin()[i];
        }

        std::vector<Symmetry> in_vec_syms = in_syms;

        this->Init(dim,in_vec_qnums,in_vec_syms,bd_type);

    }
    */


    bool Bond::operator==(const Bond &rhs) const{
        if(this->dim() != rhs.dim()) return false;
        if(this->type() != rhs.type()) return false;
        if(this->Nsym() != rhs.Nsym()) return false;
        if(this->Nsym()!=0){
            if(this->syms() != rhs.syms()) return false;
        }
        return true;        
    }
    bool Bond::operator!=(const Bond &rhs) const{
        return !(*this == rhs);
    }

    std::ostream& operator<<(std::ostream &os,const Bond &bin){
        os << "Dim = " << bin.dim() << " |";
        if(bin.type()==bondType::BD_REG){
            os << "type: REGULAR " << std::endl;
        }else if(bin.type()==bondType::BD_BRA){
            os << "type: <BRA     " << std::endl;
        }else if(bin.type()==bondType::BD_KET){
            os << "type: KET>     " << std::endl;
        }else{
            cytnx_error_msg(1,"%s","[ERROR] internal error.");
        }
        //os << bin.get_syms().size() << endl;

        for(cytnx_int32 i=0;i<bin.Nsym();i++){
            os << " " << bin.syms()[i].stype_str() << ":: ";
            for(cytnx_int32 j=0;j<bin.dim();j++){
                printf(" %+2d",bin.qnums()[j][i]);
            }
            os << std::endl;
        }
        return os;
    }

}
