FROM ubuntu:22.04 as builder
RUN mkdir -p /src /rootfs/usr/bin /rootfs/usr/sbin /rootfs/usr/lib /rootfs/usr/lib32 /rootfs/usr/lib64 /rootfs/usr/libx32
WORKDIR /rootfs
RUN ln -s usr/bin bin && ln -s usr/sbin sbin && ln -s usr/lib lib && ln -s usr/lib32 lib32 && ln -s usr/lib64 lib64 && ln -s usr/libx32 libx32
WORKDIR /src
RUN apt-get update && apt-get -y install \
    xz-utils python3 make gcc clang llvm binutils-dev libreadline-dev libelf-dev libnuma-dev libpci-dev libcap-dev gettext curl flex bison
ARG KERNEL_VERSION="6.1.69"
RUN curl -L https://cdn.kernel.org/pub/linux/kernel/v$(echo "$KERNEL_VERSION" | cut -d . -f 1).x/linux-$KERNEL_VERSION.tar.xz -o linux.tar.xz
RUN tar -xf linux.tar.xz --strip-components=1
RUN make -C tools/perf
RUN make -C tools/perf install DESTDIR=/rootfs/
RUN make -C tools/bpf
RUN make -C tools/bpf install DESTDIR=/rootfs/

FROM debian:bookworm
ARG NERDCTL_VERSION="1.7.2"
RUN mkdir /var/run/sshd /root/.ssh
EXPOSE 22
RUN sed -r -i 's/^Components: (.*)$/Components: \1 contrib/g' /etc/apt/sources.list.d/debian.sources
RUN apt-get update && apt-get install --no-install-recommends -y \
    dumb-init locales bash-completion nano vim file ca-certificates \
    libbinutils libnuma1 \
    dnsutils tcpdump elfutils gdb gdbserver strace pciutils kmod btop htop iftop nvme-cli ncdu curl netcat-openbsd iproute2 iputils-ping iptables \
    fdisk gdisk xfsprogs e2fsprogs dosfstools zfsutils-linux efibootmgr xz-utils lm-sensors openssh-server rsync dmidecode
RUN locale-gen "en_US.UTF-8"
ENV LANG=en_US.UTF-8
WORKDIR /usr/bin/
RUN curl -L https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz \
    -o - | tar -xzf - nerdctl
COPY ./entrypoint.sh /
COPY --from=builder /rootfs /
RUN apt-get clean
WORKDIR /root
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/entrypoint.sh"]