# turris-containers
## about
Goal of the project is to add LXC and Docker containers support to the Turris router. Turris router is running on PowerPC SPE e500v2 CPU (1200 MHzm 2 cores) with 2048 MB of RAM. This should be enough to run Linux containers on the device. Ability to run containers should give us some benefits, including:

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
        KERNEL_CGROUP_FREEZER=y
        CONFIG_KERNEL_CPUSETS=y
        CONFIG_KERNEL_RESOURCE_COUNTERS=y
        CONFIG_KERNEL_MEMCG=y
        CONFIG_KERNEL_MEMCG_SWAP=y
        
 Also CONFIG_PACKAGE_kmod-fs-xfs should not be enabled because its conflicting with USER_NS support (see  https://bugzilla.redhat.com/show_bug.cgi?id=917708). To use debian-unstable inside LXC container you should add line `CONFIG_MATH_EMULATION=y` to the target/linux/mpc85xx/p2020-nand/config-default file (maintainer of the powerpcspe port already contacted to resolve this). To run docker from EXT4 volumes (e.g. external flash or sdcard) you should add `CONFIG_EXT4_FS_SECURITY=y` to the target/linux/mpc85xx/p2020-nand/config-default.

2. Choose some container management software. After all i decided to use lxc (it is easy to debug and already integrated to the OpenWRT and docker, because its cool ;-)
3. Choose and enable overlay FS backend: - overlayfs is included in the OpenWRT kernel, works fine with LXC, needs some patches with docker (no support for workdir and different name in the /proc/filesystem). 
4. Create some demo containers ) I would like to move my Asterisk from OpenWRT root so this shoud be a good starting point. 
5. Create wp article and opkg packages

## problems
Go is not available on OpenWRT platform and to build it we need to use GCC 5 (gccgo in GCC4 is incomplete and buggy). uClibc is also known to not work with Go. After all i decided to use crosstool-ng and GCC 5.1 to compile Go in static mode. Also PPC and GCCGO support in the docker is available only in the trunk, so i had to use it. 

## Status
- ☑ GCCGO5 Porting to turris: done, gccgo5 (GCC 5.1) bult and tested, crosscompilation works fine, go and cgo tools are also working (tested with hello-cgo and few other projects). Static and dynamic executables are supported
- ☑ Build all docker compile time requirments (in fact only LVM and sqlite).
- ☑ Compile kernel with containers support - done. 
- ☑ Check if Namespaces/Cgroups works as expected on device - done
- ☑ Build docker using gccgo/cgo - done, with a few local patches
- ☑ Create Ububtu based image docker for repeatable builds - done, need some cleanup and publishinh
- ☑ Create container with minimal openwrt - done, created containers with TurrisOS, Debian and Busybox-static
- ☐ Test docker functionality: in progress. Working already:
    - Exec Backends: native - works, LXC - broken, unable to mount
    - Storage Backends: VFS - works, overlayfs - works, devmapper - fails, more tests needed. Other backends are untestestd
    - Docker commands tested: attach commit events exec export history images import info inspect kill load login logout logs  pause ps pull rename restart rm rmi run save search start stats stop tag top unpause version wait cp
    - Docker untested commands: diff port
    - Things known to be broken: volumes, needs some debugging. LXC exec driver fails on mount - no need to fix, "native" works well. Also devicemapper backend seems to not work. Another broken part is iptables configuration. Rule `iptables --wait -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER` returns error, probably something is missing in the kernel. Workaround - run docker daemon with `--iptables=false`


