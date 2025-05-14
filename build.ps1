# build.ps1
Write-Host "Building RaphOS..."

& "C:\Program Files\NASM\nasm.exe" bootloader/bootloader.asm -f bin -o build/bootloader.bin
Write-Host "Bootloader built."

# Build kernel
cargo build -Z build-std=core --target kernel/i386-kernel.json --manifest-path kernel/Cargo.toml --release
Write-Host "Kernel built."

# Convert kernel to bin
rust-objcopy kernel/target/i386-kernel/release/raph-kernel -O binary build/kernel.bin
Write-Host "Kernel converted to binary."

# Combine bootloader and kernel
$boot = [System.IO.File]::ReadAllBytes("build/bootloader.bin")
$kernel = [System.IO.File]::ReadAllBytes("build/kernel.bin")

# Pad the bootloader to exactly 512 bytes
if ($boot.Length -lt 512) {
    $padBoot = New-Object byte[] (512 - $boot.Length)
    $boot = $boot + $padBoot
}

# Pad the kernel to at least 512 bytes
if ($kernel.Length -lt 512) {
    $padKernel = New-Object byte[] (512 - $kernel.Length)
    $kernel = $kernel + $padKernel
}

# Combine into a full disk image
$disk = $boot + $kernel

# Write the image to disk.img
[System.IO.File]::WriteAllBytes("build/disk.img", $disk)
Write-Host "Bootloader and kernel combined."

# Run with QEMU
Write-Host "Running with QEMU..."
& "C:\Program Files\qemu\qemu-system-i386.exe" -drive format=raw,file=build/disk.img