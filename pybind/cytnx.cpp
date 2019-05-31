#include <vector>
#include <map>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>
#include <pybind11/iostream.h>
#include <pybind11/numpy.h>
#include <pybind11/buffer_info.h>

#include "../include/cytnx.hpp"
//#include "../include/cytnx_error.hpp"

namespace py = pybind11;
using namespace pybind11::literals;
using namespace cytnx;

template<class T>
void f_Tensor_setitem_scal(cytnx::Tensor &self, py::object locators, const T &rc){
    cytnx_error_msg(self.shape().size() == 0, "[ERROR] try to setelem to a empty Tensor%s","\n");
    
    size_t start, stop, step, slicelength; 
    std::vector<cytnx::Accessor> accessors;
    if(py::isinstance<py::tuple>(locators)){
        py::tuple Args = locators.cast<py::tuple>();
        // mixing of slice and ints
        for(cytnx_uint32 axis=0;axis<self.shape().size();axis++){
            if(axis >= Args.size()){accessors.push_back(Accessor::all());}
            else{ 
                // check type:
                if(py::isinstance<py::slice>(Args[axis])){
                    py::slice sls = Args[axis].cast<py::slice>();
                    if(!sls.compute(self.shape()[axis],&start,&stop,&step, &slicelength))
                        throw py::error_already_set();
                    if(slicelength == self.shape()[axis]) accessors.push_back(cytnx::Accessor::all());
                    else accessors.push_back(cytnx::Accessor::range(start,stop,step));
                }else{
                    accessors.push_back(cytnx::Accessor(Args[axis].cast<cytnx_int64>()));
                }
            }
        }
    }else{
        // only int
        for(cytnx_uint32 i=0;i<self.shape().size();i++){
            if(i==0) accessors.push_back(cytnx::Accessor(locators.cast<cytnx_int64>()));
            else accessors.push_back(cytnx::Accessor::all());
        }
    }
    
    self.set_elems(accessors,rc);
    
}


PYBIND11_MODULE(cytnx,m){

    m.attr("__version__") = "0.0.0";

    //global vars
    //m.attr("cytnxdevice") = cytnx::cytnxdevice;
    //m.attr("Type")   = py::cast(cytnx::Type);    

    py::enum_<cytnx::__type::__pybind_type>(m,"Type")
        .value("ComplexDouble", cytnx::__type::__pybind_type::ComplexDouble)
		.value("ComplexFloat", cytnx::__type::__pybind_type::ComplexFloat )	
        .value("Double", cytnx::__type::__pybind_type::Double)
		.value("Float", cytnx::__type::__pybind_type::Float  )	
        .value("Uint64", cytnx::__type::__pybind_type::Uint64)
		.value("Int64", cytnx::__type::__pybind_type::Int64  ) 	
        .value("Uint32", cytnx::__type::__pybind_type::Uint32)
		.value("Int32", cytnx::__type::__pybind_type::Int32  ) 	
		.export_values();

    py::enum_<cytnx::__device::__pybind_device>(m,"Device")
        .value("cpu", cytnx::__device::__pybind_device::cpu)
		.value("cuda", cytnx::__device::__pybind_device::cuda)	
		.export_values();


    py::class_<cytnx::Storage>(m,"Storage")
                //construction
                .def(py::init<>())
                .def(py::init<const cytnx::Storage&>())
                .def(py::init<boost::intrusive_ptr<cytnx::Storage_base> >())
                .def(py::init<const unsigned long long &, const unsigned int&, int>(),py::arg("size"), py::arg("dtype"),py::arg("device")=-1)

                .def_property_readonly("dtype",&cytnx::Storage::dtype)
                .def_property_readonly("dtype_str",&cytnx::Storage::dtype_str)
                .def_property_readonly("device",&cytnx::Storage::device)
                .def_property_readonly("device_str",&cytnx::Storage::device_str)

                .def("astype", &cytnx::Storage::astype, py::arg("new_type"))
                
                .def("__getitem__",[](cytnx::Storage &self, const unsigned long long &idx){
                    cytnx_error_msg(idx > self.size(),"idx exceed the size of storage.%s","\n");
                    py::object out;
                    if(self.dtype() == cytnx::Type.Double) 
                        out =  py::cast(self.at<cytnx::cytnx_double>(idx));
                    else if(self.dtype() == cytnx::Type.Float) 
                        out = py::cast(self.at<cytnx::cytnx_float>(idx));
                    else if(self.dtype() == cytnx::Type.ComplexDouble) 
                        out = py::cast(self.at<cytnx::cytnx_complex128>(idx));
                    else if(self.dtype() == cytnx::Type.ComplexFloat) 
                        out = py::cast(self.at<cytnx::cytnx_complex64>(idx));
                    else if(self.dtype() == cytnx::Type.Uint64) 
                        out = py::cast(self.at<cytnx::cytnx_uint64>(idx));
                    else if(self.dtype() == cytnx::Type.Int64) 
                        out = py::cast(self.at<cytnx::cytnx_int64>(idx));
                    else if(self.dtype() == cytnx::Type.Uint32) 
                        out = py::cast(self.at<cytnx::cytnx_uint32>(idx));
                    else if(self.dtype() == cytnx::Type.Int32) 
                        out = py::cast(self.at<cytnx::cytnx_int32>(idx));
                    else cytnx_error_msg(true, "%s","[ERROR] try to get element from a void Storage.");

                    return out;
                 })
                .def("__setitem__",[](cytnx::Storage &self, const unsigned long long &idx, py::object in){
                    cytnx_error_msg(idx > self.size(),"idx exceed the size of storage.%s","\n");
                    py::object out;
                    if(self.dtype() == cytnx::Type.Double) 
                        self.at<cytnx::cytnx_double>(idx) = in.cast<cytnx::cytnx_double>();
                    else if(self.dtype() == cytnx::Type.Float) 
                        self.at<cytnx::cytnx_float>(idx) = in.cast<cytnx::cytnx_float>();
                    else if(self.dtype() == cytnx::Type.ComplexDouble) 
                        self.at<cytnx::cytnx_complex128>(idx) = in.cast<cytnx::cytnx_complex128>();
                    else if(self.dtype() == cytnx::Type.ComplexFloat) 
                        self.at<cytnx::cytnx_complex64>(idx) = in.cast<cytnx::cytnx_complex64>();
                    else if(self.dtype() == cytnx::Type.Uint64) 
                        self.at<cytnx::cytnx_uint64>(idx) = in.cast<cytnx::cytnx_uint64>();
                    else if(self.dtype() == cytnx::Type.Int64) 
                        self.at<cytnx::cytnx_int64>(idx) = in.cast<cytnx::cytnx_int64>();
                    else if(self.dtype() == cytnx::Type.Uint32) 
                        self.at<cytnx::cytnx_uint32>(idx) = in.cast<cytnx::cytnx_uint32>();
                    else if(self.dtype() == cytnx::Type.Int32) 
                        self.at<cytnx::cytnx_int32>(idx) = in.cast<cytnx::cytnx_int32>();
                    else cytnx_error_msg(true, "%s","[ERROR] try to get element from a void Storage.");
                 })
                .def("__repr__",[](cytnx::Storage &self)->std::string{
                    std::cout << self << std::endl;
                    return std::string("");
                 })
                .def("__len__",[](cytnx::Storage &self)->cytnx::cytnx_uint64{return self.size();})
                
                .def("to_", &cytnx::Storage::to_, py::arg("device"))
                .def("to" , &cytnx::Storage::to , py::arg("device"))
                .def("clone", &cytnx::Storage::clone)
                .def("size", &cytnx::Storage::size)
                .def("print_info", &cytnx::Storage::print_info)
                .def("set_zeros",  &cytnx::Storage::set_zeros)
                .def("__eq__",[](cytnx::Storage &self, const cytnx::Storage &rhs)->bool{return self == rhs;})
                

                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_complex128>, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_complex64>, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_double   >, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_float    >, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_int64    >, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_uint64   >, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_int32    >, py::arg("val"))
                .def("fill",&cytnx::Storage::fill<cytnx::cytnx_uint32   >, py::arg("val"))
                ;

    py::class_<cytnx::Tensor>(m,"Tensor")
                //construction
                .def(py::init<>())
                .def(py::init<const cytnx::Tensor&>())
                .def(py::init<const std::vector<cytnx::cytnx_uint64>&, const unsigned int&, int>(),py::arg("size"), py::arg("dtype"),py::arg("device")=-1)
                .def_property_readonly("dtype",&cytnx::Tensor::dtype)
                .def_property_readonly("dtype_str",&cytnx::Tensor::dtype_str)
                .def_property_readonly("device",&cytnx::Tensor::device)
                .def_property_readonly("device_str",&cytnx::Tensor::device_str)
                .def_property_readonly("shape",&cytnx::Tensor::shape)
                
                .def("clone", &cytnx::Tensor::clone)
                .def("to", &cytnx::Tensor::to, py::arg("device"))
                .def("to_", &cytnx::Tensor::to_, py::arg("device"))
                .def("is_contiguous", &cytnx::Tensor::is_contiguous)
                .def("permute_",[](cytnx::Tensor &self, py::args args){
                    std::vector<cytnx::cytnx_uint64> c_args = args.cast< std::vector<cytnx::cytnx_uint64> >();
                    std::cout << c_args.size() << std::endl;
                    self.permute_(c_args);
                })
                .def("permute",[](cytnx::Tensor &self, py::args args)->cytnx::Tensor{
                    std::vector<cytnx::cytnx_uint64> c_args = args.cast< std::vector<cytnx::cytnx_uint64> >();
                    std::cout << c_args.size() << std::endl;
                    return self.permute(c_args);
                })
                .def("contiguous",&cytnx::Tensor::contiguous)
                .def("contiguous_",&cytnx::Tensor::contiguous_)
                .def("reshape_",[](cytnx::Tensor &self, py::args args){
                    std::vector<cytnx::cytnx_int64> c_args = args.cast< std::vector<cytnx::cytnx_int64> >();
                    std::cout << c_args.size() << std::endl;
                    self.reshape_(c_args);
                })
                .def("reshape",[](cytnx::Tensor &self, py::args args)->cytnx::Tensor{
                    std::vector<cytnx::cytnx_int64> c_args = args.cast< std::vector<cytnx::cytnx_int64> >();
                    std::cout << c_args.size() << std::endl;
                    return self.reshape(c_args);
                })
                .def("astype", &cytnx::Tensor::astype,py::arg("new_type"))
                .def("item",[](cytnx::Tensor &self){
                    py::object out;
                    if(self.dtype() == cytnx::Type.Double) 
                        out =  py::cast(self.item<cytnx::cytnx_double>());
                    else if(self.dtype() == cytnx::Type.Float) 
                        out = py::cast(self.item<cytnx::cytnx_float>());
                    else if(self.dtype() == cytnx::Type.ComplexDouble) 
                        out = py::cast(self.item<cytnx::cytnx_complex128>());
                    else if(self.dtype() == cytnx::Type.ComplexFloat) 
                        out = py::cast(self.item<cytnx::cytnx_complex64>());
                    else if(self.dtype() == cytnx::Type.Uint64) 
                        out = py::cast(self.item<cytnx::cytnx_uint64>());
                    else if(self.dtype() == cytnx::Type.Int64) 
                        out = py::cast(self.item<cytnx::cytnx_int64>());
                    else if(self.dtype() == cytnx::Type.Uint32) 
                        out = py::cast(self.item<cytnx::cytnx_uint32>());
                    else if(self.dtype() == cytnx::Type.Int32) 
                        out = py::cast(self.item<cytnx::cytnx_int32>());
                    else cytnx_error_msg(true, "%s","[ERROR] try to get element from a void Storage.");
                    return out;
                 })
                .def("storage",&cytnx::Tensor::storage)
                .def("__repr__",[](cytnx::Tensor &self)->std::string{
                    std::cout << self << std::endl;
                    return std::string("");
                 })
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_complex128>, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_complex64>, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_double   >, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_float    >, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_int64    >, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_uint64   >, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_int32    >, py::arg("val"))
                .def("fill",&cytnx::Tensor::fill<cytnx::cytnx_uint32   >, py::arg("val"))

                .def("__getitem__",[](const cytnx::Tensor &self, py::object locators){
                    cytnx_error_msg(self.shape().size() == 0, "[ERROR] try to getitem from a empty Tensor%s","\n");
                    
                    size_t start, stop, step, slicelength; 
                    std::vector<cytnx::Accessor> accessors;
                    if(py::isinstance<py::tuple>(locators)){
                        py::tuple Args = locators.cast<py::tuple>();
                        // mixing of slice and ints
                        for(cytnx_uint32 axis=0;axis<self.shape().size();axis++){
                            if(axis >= Args.size()){accessors.push_back(Accessor::all());}
                            else{ 
                                // check type:
                                if(py::isinstance<py::slice>(Args[axis])){
                                    py::slice sls = Args[axis].cast<py::slice>();
                                    if(!sls.compute(self.shape()[axis],&start,&stop,&step, &slicelength))
                                        throw py::error_already_set();
                                    if(slicelength == self.shape()[axis]) accessors.push_back(cytnx::Accessor::all());
                                    else accessors.push_back(cytnx::Accessor::range(start,stop,step));
                                }else{
                                    accessors.push_back(cytnx::Accessor(Args[axis].cast<cytnx_int64>()));
                                }
                            }
                        }
                    }else{
                        // only int
                        for(cytnx_uint32 i=0;i<self.shape().size();i++){
                            if(i==0) accessors.push_back(cytnx::Accessor(locators.cast<cytnx_int64>()));
                            else accessors.push_back(cytnx::Accessor::all());
                        }
                    }
                    
                    return self.get_elems(accessors);
                    
                })

                .def("__setitem__",[](cytnx::Tensor &self, py::object locators, const cytnx::Tensor &rhs){
                    cytnx_error_msg(self.shape().size() == 0, "[ERROR] try to setelem to a empty Tensor%s","\n");
                    
                    size_t start, stop, step, slicelength; 
                    std::vector<cytnx::Accessor> accessors;
                    if(py::isinstance<py::tuple>(locators)){
                        py::tuple Args = locators.cast<py::tuple>();
                        // mixing of slice and ints
                        for(cytnx_uint32 axis=0;axis<self.shape().size();axis++){
                            if(axis >= Args.size()){accessors.push_back(Accessor::all());}
                            else{ 
                                // check type:
                                if(py::isinstance<py::slice>(Args[axis])){
                                    py::slice sls = Args[axis].cast<py::slice>();
                                    if(!sls.compute(self.shape()[axis],&start,&stop,&step, &slicelength))
                                        throw py::error_already_set();
                                    if(slicelength == self.shape()[axis]) accessors.push_back(cytnx::Accessor::all());
                                    else accessors.push_back(cytnx::Accessor::range(start,stop,step));
                                }else{
                                    accessors.push_back(cytnx::Accessor(Args[axis].cast<cytnx_int64>()));
                                }
                            }
                        }
                    }else{
                        // only int
                        for(cytnx_uint32 i=0;i<self.shape().size();i++){
                            if(i==0) accessors.push_back(cytnx::Accessor(locators.cast<cytnx_int64>()));
                            else accessors.push_back(cytnx::Accessor::all());
                        }
                    }
                    
                    self.set_elems(accessors,rhs);
                    
                })
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_complex128>) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_complex64> ) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_double>) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_float> ) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_int64>) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_uint64> ) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_int32>) 
                .def("__setitem__",&f_Tensor_setitem_scal<cytnx_uint32> )
 
                //arithmetic >>
                .def("__add__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Add(rhs);})
                .def("__add__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Add(rhs);})

                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &lhs){return cytnx::linalg::Add(lhs,self);})
                .def("__radd__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &lhs){return cytnx::linalg::Add(lhs,self);})
 
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Add_(rhs);}) // these will return self!
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Add_(rhs);})
                .def("__iadd__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Add_(rhs);})


                .def("__sub__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Sub(rhs);})
                .def("__sub__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Sub(rhs);})

                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &lhs){return cytnx::linalg::Sub(lhs,self);})
                .def("__rsub__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &lhs){return cytnx::linalg::Sub(lhs,self);})
 
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Sub_(rhs);}) // these will return self!
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Sub_(rhs);})
                .def("__isub__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Sub_(rhs);})

                .def("__mul__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Mul(rhs);})
                .def("__mul__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Mul(rhs);})

                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &lhs){return cytnx::linalg::Mul(lhs,self);})
                .def("__rmul__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &lhs){return cytnx::linalg::Mul(lhs,self);})
 
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Mul_(rhs);}) // these will return self!
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Mul_(rhs);})
                .def("__imul__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Mul_(rhs);})


                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Div(rhs);})
                .def("__truediv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Div(rhs);})

                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rtruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &lhs){return cytnx::linalg::Div(lhs,self);})
 
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Div_(rhs);}) // these will return self!
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Div_(rhs);})
                .def("__itruediv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Div_(rhs);})

                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Div(rhs);})
                .def("__floordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Div(rhs);})

                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &lhs){return cytnx::linalg::Div(lhs,self);})
                .def("__rfloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &lhs){return cytnx::linalg::Div(lhs,self);})
 
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::Tensor &rhs){return self.Div_(rhs);}) // these will return self!
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex128&rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_complex64 &rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_double    &rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_float     &rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_int64     &rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint64    &rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_int32     &rhs){return self.Div_(rhs);})
                .def("__ifloordiv__",[](cytnx::Tensor &self, const cytnx::cytnx_uint32    &rhs){return self.Div_(rhs);})



                //linalg >>
                .def("Svd",&cytnx::Tensor::Svd, py::arg("is_U"), py::arg("is_vT"))
                .def("Eigh",&cytnx::Tensor::Eigh, py::arg("is_V"))
                .def("Inv_",&cytnx::Tensor::Inv_)
                .def("Inv",&cytnx::Tensor::Inv_)
                .def("Conj_",&cytnx::Tensor::Conj_)
                .def("Conj",&cytnx::Tensor::Conj_)
                .def("Exp_",&cytnx::Tensor::Exp_)
                .def("Exp",&cytnx::Tensor::Exp)
                ;

}
