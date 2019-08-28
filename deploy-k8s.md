# 使用kubeadm快速构建k8s环境

## 准备环境

1. 系统准备centos7.6以上
2. 关闭firewalld和selinux

## 安装docker

1. 下载docker的yum源

    ```bash
    [root@openshift2 ~]# sudo curl -o /etc/yum.repos.d/docker-ce.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    ```
2. 安装docker

    ```bash
    [root@openshift2 ~]# sudo yum install docker-ce -y
    ```
3. 启动docker

    ```bash
    [root@openshift2 ~]# sudo systemctl start docker && sudo systemctl enable docker
    ```

## 安装kubeadm, kubectl, kubelet

1. 设置阿里的kubeadm源

    ```bash
    # root 用户直接使用cat即可
    cat > /etc/yum.repos.d/kubernetes.repo << EOF
    [kubernetes]
    name=Kubernetes Repo
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
    gpgcheck=1
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
    enable=1
    EOF
    #非root用户，使用sudo vi  /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes Repo
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
    gpgcheck=1
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
    enable=1
    ```
2. 安装kubeadm等

    ```bash
    [root@openshift2 ~]# sudo yum install -y kubelet kubeadm kubectl
    ```
3. load k8s image镜像

    ```bash
    # k8simg.tar为docker image的压缩包，离线提供。
    [root@openshift2 ~]# sudo docker load < k8simg.tar
    ```
    [下载链接](https://seafile.sh.99cloud.net/f/829d5212ca404db2a908/?dl=1)
4. 关闭swap分区（如果有的话）

    ```bash
    [root@openshift2 ~]# swapoff -a
    # 注释掉/etc/fstab中的自动挂载。
    ```、
5.  设置内核参数

    ```bash
    #使用root账户，或者使用sudo 执行以下命令。
    [root@k8s-master ~]# cat /proc/sys/net/bridge/bridge-nf-call-iptables
    0
    [root@k8s-master ~]# cat /proc/sys/net/bridge/bridge-nf-call-ip6tables
    0
    #如果这两个值为1,则不需要操作，如果是0，按照如下修改
    echo "net.bridge.bridge-nf-call-iptables = 1" >>/etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-ip6tables = 1" >>/etc/sysctl.conf
    #使生效
    [root@k8s-master ~]# sysctl -p
    ```

## 部署k8s集群

1. 使用kubeadm初始化集群

    ```bash
    #使用的是flannel网络
    kubeadm init --pod-network-cidr=10.244.0.0/16
    ```
2. 根据提示拷贝配置文件到对应的目录

    ```
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
3. 完成后部署网络插件

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml
    ```
4. 检查部署之后的环境

    ```
    [root@openshift2 bin]# kubectl  get nodes
    NAME                STATUS   ROLES    AGE   VERSION
    openshift2.shared   Ready    master   69m   v1.15.3
    [root@openshift2 bin]# kubectl  get pods --all-namespaces
    NAMESPACE     NAME                                        READY   STATUS        RESTARTS   AGE
    kube-system   coredns-5c98db65d4-5wgb6                    1/1     Running       0          68m
    kube-system   coredns-5c98db65d4-fv6nb                    1/1     Running       0          68m
    kube-system   etcd-openshift2.shared                      1/1     Running       0          68m
    kube-system   kube-apiserver-openshift2.shared            1/1     Running       0          67m
    kube-system   kube-controller-manager-openshift2.shared   1/1     Running       0          68m
    kube-system   kube-flannel-ds-amd64-vfhn2                 1/1     Running       0          63m
    kube-system   kube-proxy-vvgjv                            1/1     Running       0          68m
    kube-system   kube-scheduler-openshift2.shared            1/1     Running       0          67m
    [root@openshift2 bin]#
    ```

## 添加节点

1. 在另一台机器上，完成上述"部署k8s集群"之前所有操作
2. 在master执行kubeadm init 之后会有加入集群的提示，如下图
3. ![join](img/join.png)
4. 内如如下

    ```
    [centos@k8s-slave ~]$ kubeadm join 192.168.11.15:6443 --token   8lrj88.951kc5gn2hgrppts \--discovery-token-ca-cert-hash    sha256:eaf73dff349a3e2b7ba91961a89eed4617746fb8d85d7e79761b32106cb640b6
    ```
5. 如果没有保存上一个步骤，则执行如下命令获取（在master节点上）

    ```bash
    #获取token
    [centos@k8s-master ~]$ kubeadm  token list
    #获取ca的hash值
    [centos@k8s-master ~]$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
    ```
6. 拼接join命令

    ```bash
    #使用上面查询到的结果，分别替代$token和$ca_hash值
    kubeadm join $master_ip:6443 --token $token --discovery-token-ca-cert-hash sha256:$ca_hash 
    ```
