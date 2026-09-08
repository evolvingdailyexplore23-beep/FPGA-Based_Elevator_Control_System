# FPGA-Based Elevator Control System 🛗

Designed and implemented a hardware-level elevator control system on an FPGA platform using Verilog HDL. The system leverages sequential logic and finite state machines (FSM) to coordinate concurrent floor requests, precise mechanical timing, and real-time hardware visualization[cite: 1, 2]. 

## ✨ Key Features

*   **Finite State Machine (FSM):** Engineered a robust FSM to manage four distinct operational states: `stop` (stationary), `up` (moving upward), `down` (moving downward), and `door` (opening/closing)[cite: 1, 2].
*   **Multi-Frequency Clock Division:** Down-sampled a 100 MHz system clock (`CLK`) to achieve precise timing constraints: 1 Hz for floor-to-floor travel, 2 Hz for door operations, and 1 kHz for 7-segment display multiplexing.
*   **Automated Door Logic:** Implemented automated door control that keeps the doors fully open for 3 seconds before automatically initiating the closing sequence[cite: 1, 2].
*   **Hardware Visualization:** Integrated hardware peripherals for real-time system tracking:
    *   **7-Segment Displays:** Multiplexed displays (`LEFTEN`, `RIGHTEN`, `LEFT_DISPLAY`, `RIGHT_DISPLAY`) to indicate the current operational state and track the floor position (Floor 1 to Floor 2)[cite: 1, 2, 3].
    *   **LED Arrays:** Utilized `LED[15:2]` to animate and simulate the door opening/closing behavior, while `LED[1:0]` visually indicate pending external floor requests[cite: 1, 2, 3].
*   **Robust Input Handling:** Processes concurrent internal cabin destination selections (`ELE_IN`, `ENTER`) and external floor calls (`UP`, `DOWN`), with a reliable asynchronous active-low reset (`RSTN`)[cite: 1, 2, 3].

## 📝 File Structure & Description

| File Name | Module Level | Description |
|---|---|---|
| [`lab5_4.v`](lab5_4.v) | **Top & Sub Module** | Contains the top-level integration (`Elevator_System_Design`) and the core logic (`Lab5_4`), encompassing the FSM, clock dividers, and hardware decoders[cite: 3]. |

## 🕹️ Hardware I/O Mapping

| Signal Name | Direction | Function |
|---|---|---|
| `CLK` / `RSTN` | Input | 100MHz system clock / Asynchronous active-low reset[cite: 1, 2, 3]. |
| `UP` / `DOWN` | Input | External requests from Floor 1 (Up) and Floor 2 (Down)[cite: 1, 2, 3]. |
| `ELE_IN` / `ENTER` | Input | Internal cabin floor selection (0=Floor 1, 1=Floor 2) and confirmation button[cite: 1, 2, 3]. |
| `OPEN` / `CLOSE` | Input | Manual door override buttons (effective only in `stop` or `door` states)[cite: 1, 2, 3]. |
| `LEFT_DISPLAY` | Output | 7-segment output displaying the current FSM state (e.g., "Stop", "Up", "dn")[cite: 1, 2, 3]. |
| `RIGHT_DISPLAY` | Output | 7-segment output displaying the current floor and internal requests[cite: 1, 2, 3]. |
| `LED[15:0]` | Output | Door animation simulation (`LED[15:2]`) and external request indicators (`LED[1:0]`)[cite: 1, 2, 3]. |


---
*Note: This project was developed as a comprehensive practice of digital system design, focusing on hardware-level state control and peripheral integration.*
