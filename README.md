# turris-containers
## about
Goal of the project is to add LXC containers support to the Turris router. Turris router is running on PPC e500v2 CPU (1200 MHzm 2 cores) with 2048 MB of RAM. This should be enough to run LXC-based containers on the device. Ability to run containers should give us some benefits, including:

- better security because of service isolation
- ability to run different Linux distribution (e.g. Debian PPC) on the same hardware, without reflashing your router
- Fine grained resource control 
- Separate network stack/routing table for the applcation

## plans
Currently project is on very early status, virtually nothing is done :) To use containers on Turris we will need:

1. Enable LXC and Namespace support on Kernel and test that its really works. This should be an easy step - Turris is running on Recent kernel (3.10.49) so i am not expecting that any backporting will be required. Tool `lxc-checkconfig` can validate is everything is fine witht this. Currently it seems that this configuration should be required:

        CONFIG_KERNEL_NAMESPACES=y
        CONFIG_KERNEL_UTS_NS=y
        CONFIG_KERNEL_IPC_NS=y
        CONFIG_KERNEL_PID_NS=y
        CONFIG_KERNEL_USER_NS=y
        CONFIG_KERNEL_NET_NS=y
        CONFIG_KERNEL_LXC_MISC=y
        CONFIG_KERNEL_CGROUPS=y
        CONFIG_KERNEL_CGROUP_DEVICE=y
        CONFIG_KERNEL_CGROUP_SCHED=y
        CONFIG_KERNEL_CGROUP_CPUACCT=y
        CONFIG_KERNEL_CPUSETS=y
        CONFIG_KERNEL_RESOURCE_COUNTERS=y
        CONFIG_KERNEL_MEMCG=y
        CONFIG_KERNEL_MEMCG_SWAP=y

2. Choose some container management software. Initially i was thinking about Docker, because it is already ported to ARM and code is very easy portable, but as downside - it is written on Go language, which is not officially supported on PPC/OpenWRT (see problems section). Other options to investigate: [LXD](http://www.ubuntu.com/cloud/tools/lxd), https://lxc-webpanel.github.io, http://docs.vagrantup.com/ ?
3. ~~Choose and enable overlay FS backend: aufs (will require kernel patches), overlayfs (in kernel from 3.18, there are some [patches for 3.10](https://github.com/adilinden/overlayfs-patches), and also [in OpenWRT](https://dev.openwrt.org/browser/trunk/target/linux/generic/patches-3.10/100-overlayfs.patch)).~~ *Update: overlayfs is already in the kernel*.
4. Create some demo containers ) I would like to move my Asterisk from OpenWRT root so this shoud be a good starting point. 

## problems
Go language is not available for the OpenWRT trunk. There is a [github project](https://github.com/GeertJohan/openwrt-go) but it will require to use EGLIBC instead of uclibc used by default. This switch itself could be dangerous. I tried to compile OpenWRT with EGLIBC but it fails with some asm related error. I have found information that it is possible to run glibc on e500v2, so it is subject to investigate (wrong gcc flags? some patches needed?). Also it is unlikely that libc change will ever be accepted by upstream. Another option is to compile golang or Docker statically to avoid host Libc usage. This could be achivable outside openwrt, using [crosstool-ng](http://crosstool-ng.org) which supports e500v2/Linux platform. Another problem is that Docker is built using gc compiler which is not ported to the PPC. There is also gccgo compiler which should work on PPC platform and there is github issue with Docker patches for gccgo (https://github.com/docker/docker/issues/9207). Probably good idea whould be to try to build docker using gccgo on native x86_64 Linux to see if it works. 

## links

