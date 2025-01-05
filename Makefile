MAKEFILE_DIR := $(abspath $(shell dirname $(lastword $(MAKEFILE_LIST))))
NVIDIA_CONFTEST ?= $(MAKEFILE_DIR)/out/nvidia-conftest

all: nvidia-nvgpu-modules nvidia-oot-modules alvium-driver-modules 
install: nvidia-modules-install alvium-driver-modules-install

# Build a tarball for installation on Nano
# Some serious tar black magic for transforming the absolute INSTALL_MOD_PATH
# to the relative path install/
# Need -P option to _not_ strip the leading slash, 
# so the regex (which includes the leading slash) works
package: install
	install -m 755 install.sh $(INSTALL_MOD_PATH)
	tar --transform "flags=r;s|$(INSTALL_MOD_PATH)|install|" -Pcjf alvium_install.tar.bz2  $(INSTALL_MOD_PATH)

alvium-driver-modules: nvidia-oot-modules
	$(MAKE)  -j $(NPROC) \
		KBUILD_EXTRA_SYMBOLS=$(MAKEFILE_DIR)/nvidia-oot/Module.symvers \
		CONFIG_TEGRA_OOT_MODULE=y \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.alvium-csi2-driver=$(MAKEFILE_DIR)/alvium-csi2-driver \
		M=$(MAKEFILE_DIR)/alvium-csi2-driver \
		-C $(KERNEL_SRC) 

alvium-driver-modules-install: alvium-driver-modules
	$(MAKE) \
		KBUILD_EXTRA_SYMBOLS=$(MAKEFILE_DIR)/nvidia-oot/Module.symvers \
		CONFIG_TEGRA_OOT_MODULE=y \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		KERNEL_SRC=$(KERNEL_SRC) \
		-C $(MAKEFILE_DIR)/alvium-csi2-driver install


nvidia-oot-conftest: check-env
	mkdir -p $(NVIDIA_CONFTEST)/nvidia;
	cp -av $(MAKEFILE_DIR)/nvidia-oot/scripts/conftest/* $(NVIDIA_CONFTEST)/nvidia
	$(MAKE) -j $(NPROC) ARCH=arm64 \
		src=$(NVIDIA_CONFTEST)/nvidia obj=$(NVIDIA_CONFTEST)/nvidia \
		CC=$(CROSS_COMPILE)gcc LD=$(CROSS_COMPILE)ld \
		NV_KERNEL_SOURCES=$(KERNEL_SRC) \
		NV_KERNEL_OUTPUT=$(KERNEL_SRC) \
		-f $(NVIDIA_CONFTEST)/nvidia/Makefile
		
nvidia-hwpm-modules: nvidia-oot-conftest
	$(MAKE)  -j $(NPROC) \
		CONFIG_TEGRA_OOT_MODULE=m \
		srctree.hwpm=$(MAKEFILE_DIR)/nvidia-hwpm \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		M=$(MAKEFILE_DIR)/nvidia-hwpm/drivers/tegra/hwpm  \
		-C $(KERNEL_SRC) \
		modules

nvidia-hwpm-modules-install: nvidia-hwpm-modules
	$(MAKE) \
		CONFIG_TEGRA_OOT_MODULE=m \
		srctree.hwpm=$(MAKEFILE_DIR)/nvidia-hwpm \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		M=$(MAKEFILE_DIR)/nvidia-hwpm/drivers/tegra/hwpm  \
		-C $(KERNEL_SRC) \
		modules_install
		
		
nvidia-oot-modules: nvidia-oot-conftest nvidia-hwpm-modules
	cp -av $(MAKEFILE_DIR)/nvidia-nvethernetrm $(MAKEFILE_DIR)/nvidia-oot/drivers/net/ethernet/nvidia/nvethernet/nvethernetrm
	$(MAKE)  -j $(NPROC) \
		CONFIG_TEGRA_OOT_MODULE=m \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		srctree.hwpm=$(MAKEFILE_DIR)/nvidia-hwpm \
		KBUILD_EXTRA_SYMBOLS=$(MAKEFILE_DIR)/nvidia-hwpm/drivers/tegra/hwpm/Module.symvers \
		M=$(MAKEFILE_DIR)/nvidia-oot \
		-C $(KERNEL_SRC) \
		modules

nvidia-oot-modules-install: nvidia-oot-modules
	$(MAKE) \
		CONFIG_TEGRA_OOT_MODULE=m \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		srctree.hwpm=$(MAKEFILE_DIR)/nvidia-hwpm \
		KBUILD_EXTRA_SYMBOLS=$(MAKEFILE_DIR)/nvidia-hwpm/drivers/tegra/hwpm/Module.symvers \
		M=$(MAKEFILE_DIR)/nvidia-oot \
		-C $(KERNEL_SRC) \
		modules_install

nvidia-nvgpu-modules: nvidia-oot-modules nvidia-oot-conftest
	$(MAKE) -j $(NPROC) \
		CONFIG_TEGRA_OOT_MODULE=m \
		KBUILD_EXTRA_SYMBOLS=$(MAKEFILE_DIR)/nvidia-oot/Module.symvers \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvidia=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		M=$(MAKEFILE_DIR)/nvidia-nvgpu/drivers/gpu/nvgpu  \
		-C $(KERNEL_SRC) \
		modules

nvidia-nvgpu-modules-install: nvidia-nvgpu-modules
	$(MAKE) \
		CONFIG_TEGRA_OOT_MODULE=m \
		KBUILD_EXTRA_SYMBOLS=$(MAKEFILE_DIR)/nvidia-oot/Module.symvers \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvidia=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		M=$(MAKEFILE_DIR)/nvidia-nvgpu/drivers/gpu/nvgpu  \
		-C $(KERNEL_SRC) \
		modules_install

nvidia-modules-install: nvidia-nvgpu-modules-install nvidia-oot-modules-install nvidia-hwpm-modules-install


check-env:
ifndef ARCH
      $(error Environment variable ARCH must be defined)
endif
ifndef CROSS_COMPILE
      $(error Environment variable CROSS_COMPILE must be defined)
endif
ifndef KERNEL_SRC
      $(error Environment variable KERNEL_SRC must be defined)
endif
	if [ ! -d "$(KERNEL_SRC)" ]; then \
        echo "$(KERNEL_SRC) does not exist!"; \
        exit 1; \
    fi


clean: 
	rm -rf out/
	$(MAKE) \
		srctree.nvidia-oot=$(MAKEFILE_DIR)/nvidia-oot \
		srctree.nvconftest=$(NVIDIA_CONFTEST) \
		srctree.hwpm=$(MAKEFILE_DIR)/nvidia-hwpm \
		M=$(MAKEFILE_DIR)/nvidia-oot -C $(KERNEL_SRC) clean