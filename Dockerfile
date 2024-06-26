FROM debian:bookworm as builder
RUN mkdir -p /src /rootfs/usr/bin /rootfs/usr/sbin /rootfs/usr/lib /rootfs/usr/lib32 /rootfs/usr/lib64 /rootfs/usr/libx32
WORKDIR /rootfs
RUN ln -s usr/bin bin && ln -s usr/sbin sbin && ln -s usr/lib lib && ln -s usr/lib32 lib32 && ln -s usr/lib64 lib64 && ln -s usr/libx32 libx32
WORKDIR /src
RUN apt-get update && apt-get -y install \
    xz-utils python3 python3-dev python3-setuptools make gcc clang pkg-config llvm binutils-dev libreadline-dev libelf-dev libnuma-dev libpci-dev libcap-dev gettext curl flex bison libssl-dev libslang2-dev libtraceevent-dev
ARG KERNEL_VERSION="6.6.29"
RUN curl -L https://cdn.kernel.org/pub/linux/kernel/v$(echo "$KERNEL_VERSION" | cut -d . -f 1).x/linux-$KERNEL_VERSION.tar.xz -o linux.tar.xz
RUN tar -xf linux.tar.xz --strip-components=1
RUN make -C tools/perf
RUN make -C tools/perf install DESTDIR=/rootfs/
RUN make -C tools/bpf
RUN make -C tools/bpf install DESTDIR=/rootfs/

FROM debian:bookworm
ARG NERDCTL_VERSION="1.7.4"
RUN mkdir /var/run/sshd /root/.ssh
EXPOSE 22
RUN apt-get update && apt-get install --no-install-recommends -y \
    dumb-init locales bash-completion nano vim file ca-certificates \
    libbinutils libnuma1 numactl \
    libslang2 libtraceevent1 \
    dnsutils tcpdump elfutils gdb gdbserver strace pciutils kmod btop htop iftop \
    nvme-cli ncdu curl netcat-openbsd iproute2 iputils-ping iptables nftables bpftrace \
    sg3-utils fdisk gdisk xfsprogs e2fsprogs dosfstools efibootmgr xz-utils lvm2 lm-sensors openssh-server rsync dmidecode thunderbolt-tools libhugetlbfs-bin
RUN apt-get clean
RUN locale-gen "en_US.UTF-8"
ENV LANG=en_US.UTF-8
WORKDIR /usr/bin/
RUN curl -L https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz \
    -o - | tar -xzf - nerdctl
COPY ./entrypoint.sh /
COPY --from=builder /rootfs /
WORKDIR /root
RUN echo 'alias iscsiadm="chroot /host /usr/local/sbin/iscsiadm"' >> .bashrc
RUN echo 'alias mdadm="chroot /host /usr/local/sbin/mdadm"' >> .bashrc
RUN echo 'alias tgtadm="chroot /host /usr/local/sbin/tgtadm"' >> .bashrc
RUN echo 'alias zdb="chroot /host /usr/local/sbin/zdb"' >> .bashrc
RUN echo 'alias zfs="chroot /host /usr/local/sbin/zfs"' >> .bashrc
RUN echo 'alias zpool="chroot /host /usr/local/sbin/zpool"' >> .bashrc
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/entrypoint.sh"]