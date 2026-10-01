# PE_MP Design Workbench

**[Open the PE_MP Workbench](https://lin2513lp.github.io/pe-mp-workbench/pe_mp_workbench.html)**

A multi-precision processing-element workbench for the TPU compute array. The workbench runs in a browser and requires no installation.

## Workbench contents

- PE_MP_v1 operation in INT4, INT8, FP16, and FP32 modes.
- Fixed-point / floating-point conversion, floating-point addition, and multiplication.
- Design reports, timing diagrams, waveform captures, and Verilog source browsing.

## Source files

[`code/`](code/) contains the current source snapshot from the shared `pe_v1` project. Relative paths and file contents are preserved, including RTL, testbenches, Makefiles, file lists, and available helper scripts. The workbench's code viewer displays this same snapshot.

There are **7 project files** in this snapshot. [`source-manifest.json`](source-manifest.json) records the shared-directory mapping and SHA-256 checksums. Generated simulator databases, waveform dumps, editor temporary files, and license logs are excluded.

## Repository layout

| Path | Contents |
| --- | --- |
| [`pe_mp_workbench.html`](pe_mp_workbench.html) | Main design workbench |
| [`code/`](code/) | Shared-project source files and build entry points |
| [`source-manifest.json`](source-manifest.json) | Source inventory and checksums |
| [`index.html`](index.html) | English project introduction and workbench link |

## Using the project

Open the workbench through the link above to browse the report, code, and waveforms. For simulation, clone this repository, enter `code/`, and use its Makefile in a configured Linux EDA environment. The original tool paths and environment variables in the shared Makefile are preserved; configure these for your installation.

## Related workbenches

- [TPU_CRG](https://github.com/Lin2513lp/TPU_CRG_WORKBENCH)
- [AXI_TOP](https://github.com/Lin2513lp/AXI_TOP_WORKBENCH)
- [AHB_SLAVE](https://github.com/Lin2513lp/AHB_SLAVE_WORKBENCH)
- [SA_TOP](https://github.com/Lin2513lp/sa-workbench)
