# Talos OS Debug tools 

Image contains tools to debug node that include:

- bpftool
- bpftrace
- btop 
- curl
- dmidecode
- dnsutils
- e2fsprogs
- elfutils
- fdisk
- gdb
- gdbserver
- gdisk
- htop 
- iftop 
- iproute2 
- iptables
- iputils-ping
- kmod 
- lm-sensors
- ncdu
- nerdctl
- netcat-openbsd 
- nftables
- numactl
- nvme-cli 
- pciutils
- perf
- rsync
- sg3-utils
- strace
- tcpdump
- xfsprogs

## Use it:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: debug-tools
  name: debug-tools
  namespace: default
spec:
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: debug-tools
  template:
    metadata:
      labels:
        app: debug-tools
    spec:
      containers:
      - args:
        - "infinity"
        command:
        - /bin/sleep
        image: ghcr.io/aarnaud/talos-debug-tools:latest-6.1.78
        imagePullPolicy: IfNotPresent
        name: debug-container
        resources: {}
        securityContext:
          allowPrivilegeEscalation: true
          privileged: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
          - name: hostfs
            mountPath: /host
          - name: run-containerd
            mountPath: /run/containerd
          - name: var-log-pods
            mountPath: /var/log/pods
      dnsPolicy: ClusterFirstWithHostNet
      hostIPC: true
      hostPID: true
      hostNetwork: true
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        runAsNonRoot: false
        seccompProfile:
          type: RuntimeDefault
      terminationGracePeriodSeconds: 30
      volumes:
        - name: hostfs
          hostPath:
            path: /
        - name: run-containerd
          hostPath:
            path: /run/containerd
        - name: var-log-pods
          hostPath:
            path: /var/log/pods
  updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate
```

Now you can exec in this containers

## Example to use zfs:

```bash
chroot /rootfs /usr/local/sbin/zpool status
```