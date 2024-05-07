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
- lvm2
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
- thunderbolt-tools
- xfsprogs

## Use it:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: sshd
  name: sshd
  namespace: kube-system
spec:
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: sshd
  template:
    metadata:
      labels:
        app: sshd
    spec:
      containers:
        - image: ghcr.io/aarnaud/talos-debug-tools:latest-6.6.29
          imagePullPolicy: IfNotPresent
          name: debug-container
          resources: {}
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              add:
                - SYS_ADMIN
            privileged: true
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /run/containerd
              name: run-containerd
            - mountPath: /var/log/pods
              name: var-log-pods
            - mountPath: /root/.ssh/authorized_keys
              name: ssh-dir
              subPath: authorized_keys
            - mountPath: /var/lib/kubelet
              mountPropagation: Bidirectional
              name: kubelet-dir
            - mountPath: /lib/modules
              name: modules-dir
              readOnly: true
            - mountPath: /etc/localtime
              name: localtime
              readOnly: true
            - mountPath: /run/udev
              name: udev-data
            - mountPath: /host
              mountPropagation: Bidirectional
              name: host-dir
            - mountPath: /sys
              name: sys-dir
            - mountPath: /dev
              name: dev-dir
            - mountPath: /sys/firmware/efi/efivars
              name: efivars
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
        - hostPath:
            path: /
            type: ""
          name: hostfs
        - hostPath:
            path: /run/containerd
            type: ""
          name: run-containerd
        - hostPath:
            path: /var/lib/kubelet/plugins
            type: Directory
          name: plugins-dir
        - hostPath:
            path: /var/lib/kubelet/plugins_registry
            type: Directory
          name: registration-dir
        - hostPath:
            path: /var/lib/kubelet
            type: Directory
          name: kubelet-dir
        - hostPath:
            path: /dev
            type: Directory
          name: dev-dir
        - hostPath:
            path: /lib/modules
            type: ""
          name: modules-dir
        - hostPath:
            path: /etc/localtime
            type: ""
          name: localtime
        - hostPath:
            path: /run/udev
            type: ""
          name: udev-data
        - hostPath:
            path: /sys
            type: Directory
          name: sys-dir
        - hostPath:
            path: /
            type: Directory
          name: host-dir
        - hostPath:
            path: /var/log/pods
            type: ""
          name: var-log-pods
        - hostPath:
            path: /sys/firmware/efi/efivars
            type: ""
          name: efivars
        - configMap:
            defaultMode: 448
            name: ssh-dir
          name: ssh-dir
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