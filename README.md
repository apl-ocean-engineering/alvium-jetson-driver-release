# Trisect-specific Allied Vision Alvium CSI driver for Jetpack 6 

Derived from the upstream Allied Vision [Alvium CSI Driver for Jetpack 6](https://github.com/alliedvision/alvium-jetson-driver-release) with local modifications specific to the [Trisect project](https://trisect-perception-sensor.gitlab.io/trisect-docs/).

This branch targets [**Jetpack 6.1**](https://developer.nvidia.com/embedded/jetpack-sdk-61) / [**L4T-36.40**](https://developer.nvidia.com/embedded/jetson-linux-r3640)


## Building

1. Clone this repository **including all submodules**

    ```shell
        git clone --recurse-submodules https://github.com/apl-ocean-engineering/alvium-jetson-driver-release.git
    ```

    or:

    ```shell
        git clone https://github.com/apl-ocean-engineering/alvium-jetson-driver-release.git
        git submodule update --init
    ```

2. Download the Jetson Linux driver package (BSP) and cross compiler (registration with Nvidia required).   The driver package / BSP  **must** match your version of Jetpack:

    * [Downloads for Jetpack 6.0 / Linux4Tegra 36.3](https://developer.nvidia.com/embedded/jetson-linux-r363)

3. Extract the driver package **in the current directory**: 

    ```shell
        tar -xvf jetson_linux_r36*.bz2
    ```
4. Extract the kernel headers from the driver package:

    ```shell
        cd Linux_for_Tegra/kernel/
        tar -xvf kernel_headers.tbz2
    ```
5. Extract the cross compiler **in the current directory**

    ```shell
        tar -xvf aarch64--glibc--stable-*.tar.bz2
    ```

6. Build the modules:
    ```shell
        export ARCH=arm64
        export CROSS_COMPILE=<path to cross compiler>/bin/aarch64-buildroot-linux-gnu-
        export KERNEL_SRC=Linux_for_Tegra/kernel/linux-headers-*-linux_x86_64/3rdparty/canonical/linux-jammy/kernel-source/
        make all 
    ```
7. Install the driver modules
    ```shell
        export INSTALL_MOD_PATH=<path to install directory>
        make install
    ```








## Compatibility
### SoMs + Carrier Boards 
- Jetson AGX Orin DevKit
- Jetson Orin Nano DevKit
- Jetson Orin NX + Jetson Orin Nano DevKit carrier
### Cameras
- All Alvium C cameras with Firmware 13 or newer

## Installation 
1. Download the two debian packages from the releases section to our target board
2. Install the packages by running:
    ```shell
    sudo apt install ./alvium-csi2-driver-<version>.deb ./avt-nvidia-l4t-kernel-oot-modules-<version>.deb
    ```
3. Configure the device tree
    1. Start the jetson-io tool
        ```shell
        sudo /opt/nvidia/jetson-io/jetson-io.py
        ```
    2. Select the CSI connector configuration
        - For AGX Orin: "Jetson AGX CSI Connector"
        - For Orin Nano / NX: "Jetson 24pin CSI Connector"
    3. Select "Configure for compatible hardware"
    4. Select the "Allied Vision Alvium Dual" configuration
    5. Select "Save pin changes" 
    6. Select "Save and reboot to reconfigure pins"
4. After the board has reboot the camera can be access with V4L2 and Vimba X

   
# Beta Disclaimer

Please be aware that all code revisions not explicitly listed in the Github Release section are
considered a **Beta Version**.

For Beta Versions, the following applies in addition to the GPLv2 License:

THE SOFTWARE IS PRELIMINARY AND STILL IN TESTING AND VERIFICATION PHASE AND IS PROVIDED ON AN “AS
IS” AND “AS AVAILABLE” BASIS AND IS BELIEVED TO CONTAIN DEFECTS. THE PRIMARY PURPOSE OF THIS EARLY
ACCESS IS TO OBTAIN FEEDBACK ON PERFORMANCE AND THE IDENTIFICATION OF DEFECTS IN THE SOFTWARE,
HARDWARE AND DOCUMENTATION.


