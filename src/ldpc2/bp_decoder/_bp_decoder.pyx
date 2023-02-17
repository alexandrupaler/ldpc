#cython: language_level=3, boundscheck=False, wraparound=False, initializedcheck=False, cdivision=True, embedsignature=True
# distutils: language = c++
import numpy as np
from scipy.sparse import spmatrix

cdef class bp_decoder_base:

    def __init__(self,pcm, **kwargs):
        pass

    def __cinit__(self,pcm, **kwargs):

        error_rate=kwargs.get("error_rate",None)
        error_channel=kwargs.get("error_channel", None)
        max_iter=kwargs.get("max_iter",0)
        bp_method=kwargs.get("bp_method",0)
        ms_scaling_factor=kwargs.get("ms_scaling_factor",1.0)
        schedule=kwargs.get("schedule", 0)
        omp_thread_count = kwargs.get("omp_thread_count", 1)
        random_serial_schedule = kwargs.get("random_serial_schedule", 0)
        serial_schedule_order = kwargs.get("serial_schedule_order", None)
        
        '''
        Docstring test
        '''

        cdef i, j
        self.MEMORY_ALLOCATED=False

        #check the parity check matrix is the right type
        if isinstance(pcm, np.ndarray) or isinstance(pcm, spmatrix):
            pass
        else:
            raise TypeError(f"The input matrix is of an invalid type. Please input a np.ndarray or scipy.sparse.spmatrix object, not {type(pcm)}")

        # get the parity check dimensions
        self.m, self.n = pcm.shape[0], pcm.shape[1]


        #bp_method input parameter
        if str(bp_method).lower() in ['prod_sum','product_sum','ps','0','prod sum']:
            bp_method=0
        elif str(bp_method).lower() in ['min_sum','minimum_sum','ms','1','minimum sum','min sum']:
            bp_method=1 # method 1 is not working (see issue 1). Defaulting to the log version of bp.
        else: raise ValueError(f"BP method '{bp_method}' is invalid.\
                            Please choose from the following methods:'product_sum',\
                            'minimum_sum'")
        self.bp_method = bp_method


        #max_iter input parameter
        if not isinstance(max_iter,int):
            raise ValueError("max_iter input parameter is invalid. This must be specified as a positive int.")
        if max_iter<0:
            raise ValueError(f"max_iter input parameter must be a postive int. Not {max_iter}.")
        if max_iter==0:
            self.max_iter = self.n
        else: self.max_iter = max_iter

        #ms_scaling_factor input parameter
        if not isinstance(ms_scaling_factor, float):
            raise ValueError("The ms_scaling factor must be specified as a float")
        self.ms_scaling_factor=ms_scaling_factor

        #schedule input parameter
        if str(schedule).lower() in ['parallel','p','0']:
            schedule=0
        elif str(schedule).lower() in ['serial','s','1']:
            schedule=1 # method 1 is not working (see issue 1). Defaulting to the log version of bp.
        else: raise ValueError(f"The BP schedule method '{schedule}' is invalid.\
                            Please choose from the following methods:1) 'schedule = parallel',\
                            'schedule=serial'")
        self.schedule = schedule

        if serial_schedule_order is None:
            self.serial_schedule_order = NULL_INT_VECTOR
        else:
            if not len(serial_schedule_order) == self.n:
                raise Exception("Input error. The `serial_schedule_order` input parameter must have length equal to the length of the code.")
            for i in range(self.n): self.serial_schedule_order[i] = serial_schedule_order[i]

        self.random_serial_schedule = random_serial_schedule

        ## thread_count
        self.omp_thread_count = omp_thread_count


        #MEMORY ALLOCATION
        self.pcm = new bp_sparse(self.m,self.n) #createst the C++ sparse matrix object
        self.error_channel.resize(self.n) #C vector for the error channel
        self.syndrome.resize(self.m) #C vector for the syndrome

        ## error channel setup
        if error_rate is None:
            if error_channel is None:
                raise ValueError("Please specify the error channel. Either: 1) error_rate: float or 2) error_channel: list of floats of length equal to the block length of the code {self.n}.")

        if error_rate is not None:
            if error_channel is None:
                if not isinstance(error_rate,float):
                    raise ValueError("The `error_rate` parameter must be specified as a single float value.")
                for i in range(self.n): self.error_channel[i] = error_rate

        if error_channel is not None:
            if len(error_channel)!=self.n:
                raise ValueError(f"The error channel vector must have length {self.n}, not {len(error_channel)}.")
            for i in range(self.n): self.error_channel[i] = error_channel[i]


        #fill sparse matrix
        if isinstance(pcm,np.ndarray):
            for i in range(self.m):
                for j in range(self.n):
                    if pcm[i,j]==1:
                        self.pcm.insert_entry(i,j,1)
        elif isinstance(pcm,spmatrix):
            rows, cols = pcm.nonzero()
            for i in range(len(rows)):
                self.pcm.insert_entry(rows[i], cols[i], pcm[rows[i], cols[i]])
        else:
            raise TypeError(f"The input matrix is of an invalid type. Please input a np.ndarray or scipy.sparse.spmatrix object, not {type(pcm)}")


        self.bpd = new bp_decoder_cpp(self.pcm,self.error_channel,self.max_iter,self.bp_method,self.ms_scaling_factor,self.schedule,self.omp_thread_count,self.serial_schedule_order,self.random_serial_schedule)
        self.MEMORY_ALLOCATED=True

    def __del__(self):
        if self.MEMORY_ALLOCATED:
            del self.bpd

    # cpdef np.ndarray[np.uint8_t, ndim=1] decode(self,uint8_t[::1] input_syndrome):
    #     self.syndrome = &input_syndrome[0] #get pointer of memoryview
    #     self.bpd.decode(self.syndrome) 
    #     # cdef uint8_t[::1] output_view = <uint8_t[:self.n]> self.bpd.decoding #convert pointer array to memory view
    #     cdef np.ndarray[np.uint8_t, ndim=1] out = np.asarray(<uint8_t[:self.n]> self.bpd.decoding) #convert memory view to numpy
    #     return out #return numpy array

    @property
    def decoding(self):
        out = np.zeros(self.n).astype(int)
        for i in range(self.n): out[i] = self.bpd.decoding[i]
        return out

    @property
    def log_prob_ratios(self):
        out=np.zeros(self.n)
        for i in range(self.n): out[i] = self.bpd.log_prob_ratios[i]
        return out

    @property
    def converge(self):
        return self.bpd.converge

    @property
    def iter(self):
        return self.bpd.iterations
        

cdef class bp_decoder(bp_decoder_base):

    def __cinit__(self,pcm, error_rate=None, error_channel=None, max_iter=0, bp_method=1, ms_scaling_factor=1.0, schedule=0, omp_thread_count = 1, random_serial_schedule = 0, serial_schedule_order = None):
        pass

    def __init__(self,pcm, error_rate=None, error_channel=None, max_iter=0, bp_method=1, ms_scaling_factor=1.0, schedule=0, omp_thread_count = 1, random_serial_schedule = 0, serial_schedule_order = None):
        
        pass

    def decode(self,syndrome):
        if not len(syndrome)==self.m:
            raise ValueError(f"The syndrome must have length {self.m}. Not {len(syndrome)}.")
        cdef int i
        cdef bool zero_syndrome = True
        DTYPE = syndrome.dtype
        
        for i in range(self.m):
            self.syndrome[i] = syndrome[i]
            if self.syndrome[i]: zero_syndrome = False
        if zero_syndrome: return np.zeros(self.n,dtype=DTYPE)
        
        self.bpd.decode(self.syndrome)
        out = np.zeros(self.n,dtype=DTYPE)
        for i in range(self.n): out[i] = self.bpd.decoding[i]
        return out

    @property
    def decoding(self):
        out = np.zeros(self.n).astype(int)
        for i in range(self.n): out[i] = self.osd.osdw_decoding[i]
        return out


    # cpdef np.ndarray[np.uint8_t, ndim=1] decode(self,uint8_t[::1] input_syndrome):
    #     self.syndrome = &input_syndrome[0] #get pointer of memoryview
    #     self.bpd.decode(self.syndrome) 
    #     # cdef uint8_t[::1] output_view = <uint8_t[:self.n]> self.bpd.decoding #convert pointer array to memory view
    #     cdef np.ndarray[np.uint8_t, ndim=1] out = np.asarray(<uint8_t[:self.n]> self.bpd.decoding) #convert memory view to numpy
    #     return out #return numpy array





