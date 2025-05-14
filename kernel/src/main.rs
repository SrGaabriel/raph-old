#![no_std]
#![no_main]

use core::arch::asm;
use core::panic::PanicInfo;

#[no_mangle]
pub extern "C" fn _start() -> ! {
    let vga_buffer = 0xb8000 as *mut u8;
    unsafe {
        *vga_buffer = b'H';
        *vga_buffer.offset(1) = 0x0F;
        *vga_buffer.offset(2) = b'i';
        *vga_buffer.offset(3) = 0x0F;
    }
    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}