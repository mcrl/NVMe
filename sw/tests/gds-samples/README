cuFile API Samples
==================

In this directory, you will find sample Programs which demonstrate usage of cuFile APIs.
Each sample is intended to show different aspect of application development using cuFile APIs.

Note: The sample tests expect the data files to be present and atleast 128MiB in size.
      The data files should have read/write permissions in GDS enabled mounts.

1. Compilation:

Note: Assuming the path to GDS package is /usr/local/cuda-10.1/gds
export CUFILE_PATH=/usr/local/cuda-10.1/targets/x86_64-linux/lib/
make

2. Samples Usage:

cufile_sample_001 : Sample file write test with cuFileBufRegister and cuFileWrite
./cufile_sample_001 <dir/file-path-1> <gpu-id>

cufile_sample_002 : Sample file write test with cuFileWrite
./cufile_sample_002 <file-path-1> <gpu-id>

cufile_sample_003 : Sample file data integrity test with cuFileRead and cuFileWrite
./cufile_sample_003 <file-path-1> <file-path-2> <gpu-id>

cufile_sample_004 : Sample file data integrity test with cuFileRead and cuFileWrite using cuda driver APIs
./cufile_sample_004 <file-path-1> <file-path-2> <gpu-id>

cufile_sample_005 : Sample file write test by passing device memory offsets
./cufile_sample_005 <file-path-1> <file-path-2> <gpu-id>

cufile_sample_006 : Sample file read test iterating over a given size of the file.
./cufile_sample_006 <file-path-1> <file-path-2> <gpu-id>

cufile_sample_007 : Sample to show set/get properties
./cufile_sample_007

cufile_sample_008 : Sample to show types of error messages from the library
./cufile_sample_008

cufile_sample_009 : Sample multithreaded example with cuFileAPIs.
This sample shows how two threads work with per-thread CUfileHandle_t
./cufilesample_009 <file-path-1> <file-path-2>

cufile_sample_010 : Sample multithreaded example with cuFileAPIs.
This sample shows how two threads can share the same CUfileHandle_t.
Note: The gpu-id1 and gpu-id2 can be the same GPU.
./cufilesample_010 <file-path-1> <gpu-id1> <gpu-id2>

cufile_sample_011 : Sample multithreaded example with cuFileAPIs without using cuFileBufRegister.
Note: The gpu-id1 and gpu-id2 can be the same GPU.
./cufilesample_011 <file-path-1> <gpu-id1> <gpu-id2>

cufile_sample_012 : Sample multithreaded example with cuFileAPIs with usage of SetMaxBar1Size and SetMaxCacheSize APIs.
This sample uses cuFileBufRegister per thread.
./cufilesample_012 <file-path-1> <file-path-2>

cufile_sample_013 : Sample multithreaded example with cuFileAPIs with usage of SetMaxBar1Size and SetMaxCacheSize APIs
This sample uses cuFileBufRegister alternately per thread.
./cufilesample_013 <file-path-1> <file-path-2>

cufile_sample_014 : Sample to use a file using cuFileRead buffer offsets
./cufilesample_014 <file-path-read> <file-path-write> <gpu-id>

cufile_sample_015 : Sample file data integrity test with cuFileRead and cuFileWrite with Managed Memory
./cufile_sample_015 <file-path-1> <file-path-2> <gpu-id> <mode>, where mode is the memory type
(DeviceMemory = 1, ManagedMemory = 2, HostMemory = 3)

cufile_sample_016: Sample to test multiple threads reading data at different file offsets and
buffer offset of a memory allocated using single allocation but registered with cuFile at different
buffer offsets in each thread.
./cufile_sample_016 <file-path>

cufile_sample_017: Sample to test multiple threads reading data at different file offsets and
buffer offsets of a memory allocated using single allocation and single buffer registered with cuFile in main thread. 
./cufile_sample_017 <file-path>

cufile_sample_018: This sample shows the usage of fcntl locks with GDS for unaligned writes to achieve atomic transactions.
./cufile_sample_018 <file-path>

There are exactly same number samples with the name cufile_sample_###_static. They are functionally same as cufile_sample_### binaries but use cufile static library.
