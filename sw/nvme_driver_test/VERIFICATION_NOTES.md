# NVMe 드라이버 빌드 + 실동작 검증 결과 (2026-06-09)

## 결론: ✅ 전부 성공 (end-to-end 검증됨)

FPGA NVMe 호스트 드라이버를 **빌드 → 비트스트림 합성 → JTAG 프로그래밍 → 실제 Samsung NVMe SSD에
대해 동작 검증**까지 모두 완료. `driver_test`가 NVMe 컨트롤러를 READY로 만들고 admin(IOCQ/IOSQ
생성) + IO write/read 커맨드를 실제로 완료시킴.

## 동작 검증 증거
| 항목 | 결과 |
|---|---|
| 비트스트림 | `hw/SYNTH/fpga-nvme-driver/fpga-nvme-driver.runs/impl_1/top.bit`, 타이밍 MET (WNS +0.116ns) |
| 프로그래밍 | 카드 **18:00.0** (JTAG `210249BE4B03`/xczu19_0), End of startup HIGH → PCIe `10ee:903f` 등장 |
| CSR | scratch 레지스터 모든 패턴 왕복 OK |
| NVMe 엔드포인트 | **144D:A808 (Samsung SSD)** — FPGA가 OcuLink로 config 읽음 |
| 컨트롤러 | CAP=3C033FFF/30, **VS=00010300 (NVMe 1.3)**, **CSTS.RDY=1 (READY)** |
| 커맨드 완료 | IOCQ/IOSQ create, IO WRITE(LBA 0xC000, A1..A8), IO READ 모두 cpl_done 0→1 전이 [COMPLETE] |

## 재현 방법

### 1. 비트스트림 빌드 (Vivado 2024.2, 라이선스 ~/.Xilinx/Xilinx.lic 필요)
```bash
export XILINXD_LICENSE_FILE=/home/junsik/.Xilinx/Xilinx.lic
source /home/junsik/opt/Vivado/2024.2/settings64.sh
cd hw/SYNTH/fpga-nvme-driver
vivado -mode batch -source /tmp/vivado_build.tcl   # open(2021.2→2024.2 업그레이드) → upgrade_ip → synth → impl → bitstream
```
- 주의: 프로젝트는 **증분합성 체크포인트**가 없는 top.dcp를 참조 → 빌드 tcl에서 해제함.
- 라이선스는 **2024.11+ 버전** 필요(2024.2). 평가판 2027.06 사용.

### 2. JTAG 프로그래밍 (root hw_server 필요)
```bash
sudo modprobe -r ftdi_sio usbserial        # FT232H를 JTAG로 쓰려면 ftdi_sio 떼야 함 (안 그러면 hw_server가 타겟 0개)
sudo bash -c 'source /home/junsik/opt/Vivado/2024.2/settings64.sh; \
  vivado -mode batch -log /tmp/prog.log -source /tmp/prog_card0.tcl'   # 내부 root hw_server가 JTAG 접근
# (root vivado batch는 stdout 버퍼링으로 -log 파일을 봐야 함)
```
프로그래밍 후 PCIe 재열거:
```bash
for b in 18:00.0 5e:00.0 86:00.0 d8:00.0; do echo 1 | sudo tee /sys/bus/pci/devices/0000:$b/remove; done
echo 1 | sudo tee /sys/bus/pci/rescan
```

### 3. driver_test 실행
```bash
cd sw/nvme_driver_test/sw && make
sudo setpci -s 18:00.0 COMMAND=0x2          # mem space enable
sudo ./driver_test /sys/bus/pci/devices/0000:18:00.0/resource0
```

## 핵심 발견 / 수정
1. **`read_csr` volatile 버그** (driver_test.c): MMIO 읽기에 `volatile`이 없어, `-O2`에서 폴링 루프
   `while(read_csr(...)==0)`가 캐시되어 무한루프. → `volatile uint32_t*` 추가로 수정. (원래 Makefile은
   -O0라 우연히 동작했음.)
2. **Makefile**: spdlog 1.5(Ubuntu 20.04)는 컴파일드-lib → `pkg-config spdlog`(`-DSPDLOG_COMPILED_LIB
   -lspdlog -pthread`)로 정상화. 누락된 `spdlog/stopwatch.h` include 제거.
3. **JTAG 안 보임**: FT232H가 `ftdi_sio`로 ttyUSB 점유 → `modprobe -r ftdi_sio` + **root** hw_server 필요.
4. **BAR 할당 실패**: 새 디자인은 BAR0(1MB user)+BAR1(64KB config)인데, 부팅 시 옛 디자인 기준으로
   브리지 윈도우가 1MB만 잡혀 **BAR1 미할당** → xdma 드라이버 probe 실패(-22). driver_test는 user BAR만
   쓰므로 **resource0 직접 mmap**으로 우회. (xdma 드라이버까지 정상화하려면 `pci=realloc` + reboot 필요 —
   warm reboot은 JTAG config 유지.)
5. 디바이스: 250-SoC 4장 = PCIe `18/5e/86/d8:00.0`. JTAG 타겟 `210249BE4B03` = 카드 `18:00.0`.
   나머지 3장은 미프로그래밍(198a:250e). 같은 방법으로 프로그래밍 가능.

## 변경된 파일 (작업 트리, 커밋 안 함)
- `sw/nvme_driver_test/sw/driver_test.c`: volatile 수정, argv 디바이스 경로, stopwatch include 제거
- `sw/nvme_driver_test/sw/Makefile`: spdlog 빌드 정상화
- `sw/nvme_driver_test/dma_ip_drivers/`: Xilinx XDMA 드라이버 clone (참고용; resource0 우회로 실제론 불필요)
