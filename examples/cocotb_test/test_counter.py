import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

@cocotb.test()
async def test_counter_basic(dut):
    """Test counter increment and reset behavior"""
    # Start clock with 10ns period
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Apply reset
    dut.rst_n.value = 0
    dut.enable.value = 0
    await Timer(25, units="ns")
    assert dut.count.value == 0, f"Expected count 0 during reset, got {dut.count.value}"

    # Release reset
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.count.value == 0, f"Expected count 0 after reset release, got {dut.count.value}"

    # Enable counter and count 5 cycles
    dut.enable.value = 1
    for expected in range(1, 6):
        await RisingEdge(dut.clk)
        await FallingEdge(dut.clk)
        assert dut.count.value == expected, f"Cycle {expected}: Expected {expected}, got {dut.count.value}"

    # Disable counter
    dut.enable.value = 0
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert dut.count.value == 5, f"Counter should hold value when disabled, got {dut.count.value}"
    dut._log.info("cocotb counter test passed successfully!")
