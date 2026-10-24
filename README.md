> 源码范围：仅本模块 RTL、内部子模块及独立 TB；其他模块源码请进入对应工作台。`code/` 不收录联调包装、构建脚本、Makefile 或说明文件。

# PE_MP Design Workbench

**[Open the PE_MP Workbench](https://lin2513lp.github.io/pe-mp-workbench/pe_mp_workbench.html)**

A multi-precision processing-element workbench for the TPU compute array. The workbench runs in a browser and requires no installation.

## Workbench contents

- PE_MP_v1 operation in INT4, INT8, FP16, and FP32 modes.
- Fixed-point / floating-point conversion, floating-point addition, and multiplication.
- Design reports, timing diagrams, waveform captures, and Verilog source browsing.

## Source files

[`code/`](code/) contains only this module’s RTL, internal submodules and standalone HDL testbenches. There are **7 RTL/TB files**. Other modules are available from their respective workbenches. [`source-manifest.json`](source-manifest.json) lists the retained source hashes.


## Repository layout

| Path | Contents |
| --- | --- |
| [`pe_mp_workbench.html`](pe_mp_workbench.html) | Main design workbench |
| [`code/`](code/) | This module’s RTL and independent HDL testbenches |
| [`source-manifest.json`](source-manifest.json) | Source inventory and checksums |
| [`index.html`](index.html) | English project introduction and workbench link |

## Using the project

Open the workbench to browse the design report, waveforms and this module’s RTL/TB. Run simulation in the original local project environment.

## Related workbenches

- [TPU_CRG](https://github.com/Lin2513lp/TPU_CRG_WORKBENCH)
- [AXI_TOP](https://github.com/Lin2513lp/AXI_TOP_WORKBENCH)
- [AHB_SLAVE](https://github.com/Lin2513lp/AHB_SLAVE_WORKBENCH)
- [SA_TOP](https://github.com/Lin2513lp/sa-workbench)
