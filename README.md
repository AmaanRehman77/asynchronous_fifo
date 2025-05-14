# Asynchronous FIFO (`asymfifo`) in SystemVerilog

A synthesizable, parameterizable dual-clock FIFO for crossing data safely (by using gray code encoding for read write pointers) between unrelated write and read clock domains.

---

## Features
- **Dual-clock interface**: Independent write (`i_wclk`) and read (`i_rclk`) domains  
- **Parameterized depth & width**: Customize data width (`DSIZE`) and FIFO depth (`DEPTH`)  
- **Full / Empty flags**: `o_wfull` indicates write-side full; `o_rempty` indicates read-side empty  
- **Metastability-safe pointers**: Gray-code pointer synchronization between domains  
- **Asynchronous resets**: Independent resets for write (`i_wrst`) and read (`i_rrst`) sides  

---

## Parameters

| Parameter | Default | Description                          |
| --------- | ------- | ------------------------------------ |
| `DSIZE`   | `32`    | Width of each FIFO entry (bits)      |
| `DEPTH`   | `8`     | Number of entries in the FIFO        |

---

## Ports

| Port         | Direction | Width             | Description                               |
| ------------ | --------- | ----------------- | ----------------------------------------- |
| **Write Side**                                              |
| `i_wclk`     | input     | —                 | Write-domain clock                        |
| `i_wrst`     | input     | —                 | Active-high write-domain reset            |
| `i_wr`       | input     | —                 | Write-enable signal                       |
| `i_wdata`    | input     | `[DSIZE-1:0]`     | Data to write                             |
| `o_wfull`    | output    | —                 | High when FIFO is full (write-side)       |
| **Read Side**                                               |
| `i_rclk`     | input     | —                 | Read-domain clock                         |
| `i_rrst`     | input     | —                 | Active-high read-domain reset             |
| `i_rd`       | input     | —                 | Read-enable signal                        |
| `o_rdata`    | output    | `[DSIZE-1:0]`     | Data output                               |
| `o_rempty`   | output    | —                 | High when FIFO is empty (read-side)       |
