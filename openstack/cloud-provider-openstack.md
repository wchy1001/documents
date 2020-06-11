# Cloud Provider OpenStack

- 什么是 Cloud Provider OpenStack？
	- Cloud Provider OpenStack 是一个托管了一系列 OpenStack 与 K8S 集成相关的组件的代码仓库。
	- 其中包括：
		- OpenStack Cloud Controller Manager
		- Octavia Ingress Controller
		- Cinder CSI Plugin
		- Keystone Webhook Authentication Authorization
		- Client Keystone
		- Cinder Standalone Provisioner
		- Manila CSI Plugin
		- Manila Provisioner
		- Barbican KMS Plugin
- 为什么要做 Cloud Provider OpenStack 这个项目？
	- K8S v1.6 之前，OpenStack Cloud Provider 只能做 Cinder 集成和 Load Balancer 的创建，而且 LB 的创建还问题多多。现在随着 OpenStack 组件和功能的增加，将 OpenStack Provider 代码独立出来，既有利于统一管理，又带来了组件协作上的便利性。
	- 云控制器管理器 OpenStack Cloud Controller Manager 整合了 Controller Manager、API、Kubelet 等三个组件中的所有依赖于 OpenStack Cloud 的逻辑，用来创建与 OpenStack Cloud 的单点集成。参考[下图](https://kubernetes.io/docs/concepts/architecture/cloud-controller/)：
		- 没有 OpenStack Cloud Provider 时
		- ![](https://d33wubrfki0l68.cloudfront.net/e298a92e2454520dddefc3b4df28ad68f9b91c6f/70d52/images/docs/pre-ccm-arch.png)
		- 有 OpenStack Cloud Provider 时
		- ![](https://d33wubrfki0l68.cloudfront.net/518e18713c865fe67a5f23fc64260806d72b38f5/61d75/images/docs/post-ccm-arch.png)
	- Octavia Ingress Controller 可以在一个 Ingress 中为多个 NodePort 类型的服务创建单一的 Load Balancer，从而避免如下 3 类问题：
		1. 为每一个 LB 类型的服务创建一个 LB 实例，带来性能问题
		1. 此类 LB 类型的服务不能配置过滤器和路由规则
		1. 传统的 Ingress Controller，比如 Nginx/HAProxy/Traefik 是无用的，因为他们本身依赖于 Cloud Provider 通过 LB 类型的 Service 来对外发布
	- Cinder CSI Plugin 使 OpenStack Cinder 支持 CSI 接口

		CSI version | CSI Sidecar Version | Cinder CSI Plugin Version | Kubernetes Version
		:------ | :------- | :------------ | :-----------
		v1.0.x | v1.0.x | v1.0.0  docker image: k8scloudprovider/cinder-csi-plugin:latest | v1.13+
		v0.3.0 | v0.3.x, v0.4.x | v0.3.0 docker image: k8scloudprovider/cinder-csi-plugin:1.13.x| v1.11, v1.12, v1.13
		v0.2.0 | v0.2.x | v0.2.0 docker image: k8scloudprovider/cinder-csi-plugin:0.2.0 | v1.10, v1.9
		v0.1.0 | v0.1.0 | v0.1.0 docker image: k8scloudprovider/cinder-csi-plugin:0.1.0| v1.9
	- Keystone Webhook Authentication Authorization 使特定的 OpenStack 用户能直接访问 Kubernetes 集群资源（ K8S 集群管理员只需要知道被允许的 OpenStack 项目名称或者角色）
	- Client Keystone 完成了客户端认证集成，使得 kubectl 和 kubelet 等命令能直接支持 Keystone API 完成认证
	- Cinder Standalone Provisioner 使得 Cinder 可以作为 K8S 集群的 Storage Class，无论这个 K8S 集群是否部署在 Openstack 上。
	- Manila CSI Plugin 提供了对 OpenStack Manila 文件共享服务的 CSI 支持
	- Manila Provisioner 提供了对 OpenStack Manila 的 PVC 实现支持，包括静态和动态申请
	- Barbican KMS Plugin 提供了对 etcd 数据的加密支持
- 主要参与者是谁？
	- VMWare
	- Catalyst Cloud
	- Elisa Oyj, Feedtrail Inc
	- Redhat & IBM
	- Huawei
- 使用场景是什么？
	- 与 OpenStack 集成的场景
- 热度怎么样？
	- 比较平均，每周 5 次 Commit 左右
	- Cinder CSI 子项目的 Open Issue 占总 Issue 数量的一半左右，是受关注的子项目
	- 其它的 Feature 开发仅限于功能实现，并不是很有热度
- 未来的发展方向如何？
	- 对该项目的开发和反馈，主要还是集中在 Cinder CSI 上
