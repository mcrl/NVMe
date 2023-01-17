#include <cstdint>

// Modified from spdk/include/spdk/nvme_spec.h

union NVMeSQEntryCDW10 {
  uint32_t raw;
  struct {
    uint32_t cns       : 8;
    uint32_t reserved  : 8;
    uint32_t cntid     : 16;
  } identify;
  struct {
		uint32_t fid       : 8;
		uint32_t reserved  : 23;
		uint32_t sv        : 1;
	} set_features;
  struct {
		uint32_t qid       : 16;
		uint32_t qsize     : 16;
	} create_io_q;
  struct {
		uint32_t lid       : 8;
		uint32_t lsp       : 4;
		uint32_t reserved  : 3;
		uint32_t rae       : 1;
		uint32_t numdl     : 16;
	} get_log_page;
};
static_assert(sizeof(NVMeSQEntryCDW10) == 4, "Incorrect size");

union NVMeFeatureNumberOfQueues {
	uint32_t raw;
	struct {
		uint32_t nsqr : 16;
		uint32_t ncqr : 16;
	} bits;
};
static_assert(sizeof(NVMeFeatureNumberOfQueues) == 4, "Incorrect size");

union NVMeSQEntryCDW11 {
	uint32_t raw;
	union NVMeFeatureNumberOfQueues feat_num_of_queues;
  struct {
		uint32_t pc       : 1;
		uint32_t qprio    : 2;
		uint32_t reserved : 13;
		uint32_t cqid     : 16;
	} create_io_sq;
	struct {
		uint32_t pc       : 1;
		uint32_t ien      : 1;
		uint32_t reserved : 14;
		uint32_t iv       : 16;
	} create_io_cq;
  struct {
		uint32_t numdu    : 16;
		uint32_t lsid     : 16;
	} get_log_page;
};
static_assert(sizeof(NVMeSQEntryCDW11) == 4, "Incorrect size");

struct NVMeSQEntry {
  // dword 0
  uint16_t opc: 8;
  uint16_t fuse: 2;
  uint16_t rsvd1: 4;
  uint16_t psdt: 2;
  uint16_t cid;

  // dword 1
  uint32_t nsid;

  // dword 2, 3
  uint32_t rsvd2;
  uint32_t rsvd3;

  // dword 4, 5
  uint64_t mptr;

  // dword 6, 7, 8, 9
  union {
    struct {
      uint64_t prp1;
      uint64_t prp2;
    } prp;
  } dptr;

  // dword 10
  union {
    uint32_t cdw10;
    union NVMeSQEntryCDW10 cdw10_bits;
  };

  // dword 11
  union {
    uint32_t cdw11;
    union NVMeSQEntryCDW11 cdw11_bits;
  };

  // dword 12
  uint32_t cdw12;

  // dword 13, 14, 15
  uint32_t cdw13;
  uint32_t cdw14;
  uint32_t cdw15;
};
static_assert(sizeof(NVMeSQEntry) == 64, "Incorrect size");

struct NVMeCQEntryStatus {
  uint16_t p: 1;
  uint16_t sc: 8;
  uint16_t sct: 3;
  uint16_t crd: 2;
  uint16_t m: 1;
  uint16_t dnr: 1;
};
static_assert(sizeof(NVMeCQEntryStatus) == 2, "Incorrect size");

struct NVMeCQEntry {
  uint32_t cdw0;
  uint32_t cdw1;
  uint16_t sqhd;
  uint16_t sqid;
  uint16_t cid;
  union {
    uint16_t status_raw;
    struct NVMeCQEntryStatus status;
  };
};
static_assert(sizeof(NVMeCQEntry) == 16, "Incorrect size");