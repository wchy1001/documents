# ceph常用操作

1. 首先进入ceph容器

    ```bash
    [root@openstack kolla-ansible]# docker exec -it -u root ceph_mon bash
    ```
2. 常用命令
    - 查看ceph的状态，如果有异常，这里都会显示

        ```bash
        (ceph-mon)[root@openstack /]# ceph -s
          cluster:
            id:     d42b820e-1cf1-45de-aa17-7c88e50cd050
            health: HEALTH_WARN
                    too few PGs per OSD (24 < min 30)

          services:
            mon: 1 daemons, quorum 192.168.1.24
            mgr: localhost(active)
            osd: 3 osds: 3 up, 3 in
            rgw: 1 daemon active

          data:
            pools:   9 pools, 72 pgs
            objects: 465 objects, 1453 MB
            usage:   1806 MB used, 74953 MB / 76759 MB avail
            pgs:     72 active+clean
        ```
    - 查看异常详情

        ```bash
        (ceph-mon)[root@openstack /]# ceph health detail
        HEALTH_WARN too few PGs per OSD (24 < min 30)
        TOO_FEW_PGS too few PGs per OSD (24 < min 30)
        ```
    - 查看pool

        ```bash
        (ceph-mon)[root@openstack /]# ceph osd pool ls
        .rgw.root
        default.rgw.control
        default.rgw.meta
        default.rgw.log
        images
        volumes
        backups
        vms
        gnocchi
        ```
    - 查看某个pool的副本数

        ```bash
        (ceph-mon)[root@openstack /]# ceph osd pool get volumes size
        size: 1
        ```
    - 修改某个pool的副本数

        ```bash
        (ceph-mon)[root@openstack /]# ceph osd pool set vms size 2
        set pool 8 size to 2
        #其他的pool执行相同操作
        ```
    - 查看某个pool的pg数

        ```bash
        (ceph-mon)[root@openstack /]# ceph osd pool get vms pg_num
        pg_num: 8
        ```
    - 修改某个pool的pg数(计算pool请看多节点部署openstack文档)

        ```
        (ceph-mon)[root@openstack /]# ceph osd pool set vms pg_num 32
        set pool 8 pg_num to 32
        (ceph-mon)[root@openstack /]# ceph osd pool set vms pgp_num 32
        set pool 8 pgp_num to 32
        ```
    - ceph 查看认证

        ```bash
        (ceph-mon)[root@openstack /]# ceph auth list
        installed auth entries:

        osd.0
            key: AQA7XHNcvMJBMxAAXBLbnSRsF/s3VZfMCaeXmA==
            caps: [mon] allow profile osd
            caps: [osd] allow *
        osd.1
            key: AQBRXHNc3DSuKhAA0O6NUfFqeS43rWEF8mqs+g==
            caps: [mon] allow profile osd
            caps: [osd] allow *
        osd.2
            key: AQBgXHNcTPL/AxAAM+DYhpSh3tBAJCwRcUapIQ==
            caps: [mon] allow profile osd
            caps: [osd] allow *
        client.admin
            key: AQAaXHNcTPmsCxAALvHovXW7ZjwoJwrbdiyuag==
            auid: 0
            caps: [mds] allow
            caps: [mgr] allow *
            caps: [mon] allow *
            caps: [osd] allow *
                 ........
        ```
    - 查看osd使用详情

        ```bash
        (ceph-mon)[root@openstack /]# ceph osd df
        ID CLASS WEIGHT  REWEIGHT SIZE   USE   AVAIL  %USE VAR  PGS
        0   hdd 1.00000  1.00000 25586M 1060M 24525M 4.15 1.76  35
                        .....
        ```
    - 查看osd是否在线

        ```bash
        (ceph-mon)[root@openstack /]# ceph osd tree
        ```
    - 查看块相关的操作

        ```bash
        (ceph-mon)[root@openstack /]# rbd ls images
        #最后一个参数是pool name
        (ceph-mon)[root@openstack /]# rbd info images/0c64097f-bb03-4b4b-9156-724e689b77a4
        #查看某一个具体的块设备详情
        (ceph-mon)[root@openstack /]# rbd export images/0c64097f-bb03-4b4b-9156-724e689b77a4  /root/image.raw
        #导出一个images为一个文件
        (ceph-mon)[root@openstack /]# rbd import /root/image.raw images/test
        #导入一个文件到ceph的pool中
        (ceph-mon)[root@openstack /]# rbd create -p vms --image test -s 1G
        #创建一个大小为1G的镜像，pool是vms，名字叫做test
        (ceph-mon)[root@openstack /]# rbd bench -p vms --io-type read  test
        bench  type read io_size 4096 io_threads 16 bytes 1073741824        pattern sequential
          SEC       OPS   OPS/SEC   BYTES/SEC
            1     57478  57496.97  235507598.09
            2    114477  57239.38  234452508.42
            3    172682  57566.82  235793677.67
            4    228887  57226.30  234398936.53
        elapsed:     4  ops:   262144  ops/sec: 57326.55  bytes/sec:        234809558.00
        #rbd 对某一个镜像做一个简单的io测试
        (ceph-mon)[root@openstack /]# rbd  snap create vms/test@snap-test
        #创建快照，cinder创建的快照就是通过这种方法，语法格式为[<pool-name>/]<image-name>@<snapshot-name>]
        (ceph-mon)[root@openstack /]# rbd snap rollback vms/test@snap-test
        #快照回滚
        (ceph-mon)[root@openstack /]# rbd rm vms/test
        Removing image: 100% complete...done.
        #删除一个image
        ```
    - 测试ceph整个集群的读写性能

        ```bash
        (ceph-mon)[root@openstack /]# rados bench -p vms 10 write --no-cleanup
        #--no-cleanup 表示测试完成后不删除测试用数据。在做读测试之前，需要使用该参数来运行一遍写测试来产生测试数据，在全部测试结束后可以运行 rados -p <pool_name> cleanup 来清理所有测试数据。
        (ceph-mon)[root@openstack /]# rados bench -p vms 10 rand
        #测试顺序读
        (ceph-mon)[root@openstack /]# rados -p vms cleanup
        #删除测试数据
        ```
3. ceph常见问题
    - 扩容(参照kolla扩容方案)
    - ceph clock skew(时钟不同步，手动同步)
    - ceph pg 不一致

        ```bash
        ceph health detail
        #找到有问题的pg
        ceph pg repair <pg>
        #修复pg
        ```
    - ceph停机维护（不让ceph自动回复，通过设置标签来做）

        ```bash
        ceph osd set noout
        ceph osd set nodeep-scrub
        ceph osd set norecover
        ceph osd set norebalance
        ceph osd set nobackfill
        #之后ceph可以停机维护
        ceph osd unset noout
        ceph osd unset nodeep-scrub
        ceph osd unset norecover
        ceph osd unset norebalance
        ceph osd unset nobackfill
        #维护结束后，取消标签
        ```
    - ceph某个pool需要特定的osd池（比如ssd池）
        1. 提取已有的CRUSH map ，使用-o参数，ceph将输出一个经过编译的CRUSH map 到您指定的文件

            ```
            ceph osd getcrushmap -o crushmap.txt
            ```
        2. 反编译你的CRUSH map ，使用-d参数将反编译CRUSH map 到通过-o 指定的文件中

            ```
            crushtool -d crushmap.txt -o crushmap-decompile
            ```
        3. 使用编辑器编辑CRUSH map（这个配置文件太多，可以网查）

            ```
            vi crushmap-decompile
            ```
        4. 重新编译这个新的CRUSH map

            ```
            crushtool -c crushmap-decompile -o crushmap-compiled
            ```
        5. 将新的CRUSH map 应用到ceph 集群中

            ```
            ceph osd setcrushmap -i crushmap-compiled
            ```
    - 换盘（kolla中换盘）
        1. 设置 ceph noout等属性

            ```
            ceph osd set noout
            ceph osd set nodeep-scrub
            ceph osd set norecover
            ceph osd set norebalance
            ceph osd set nobackfill
            ```
        2. 设置完成后，修改fstab，把有问题的磁盘卸载掉。
        3. 在ceph_mon容器里面执行

            ```
            ceph osd crush remove osd.12
            ```
        4. 删除OSD的key

            ```
            ceph auth del osd.12
            ```
        5. 删除集群OSD

            ```
            ceph osd rm 12
            ```
        6. 之后关机，更换硬盘。（如果支持热插拔，则直接换上即可。）
        7. 启动服务器，找到新的硬盘(假设是sdc)打上osd标签

            ```bash
            #如果有单独的日志分区的情况
            parted /dev/sdc –s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_C 1 -1
            #设置单独的磁盘
            #接下来重命名日志分区标签（假设是sdg）（name的值根据实际情况，3代表第三个分区）
            parted /dev/sdg name 3 KOLLA_CEPH_OSD_BOOTSTRAP_C_J
            #如果没有单独的日志分区
            parted $DISK -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1
            ```
        8. 重新部署kolla-ansible

            ```bash
            cp mutinode mutinode-2019-xxx-ceph
            #删除其他的ceph节点
            kolla-ansible -i mutinode deploy –t ceph
            #重新部署
            ```
        9. 取消参数

            ```bash
            ceph osd unset nobackfill
            ceph osd unset norecover
            ceph osd unset norebalance
            #在ceph_mon容器中执行
            ```
        10. 验证集群是否同步完成
        11. 取消剩余参数

            ```bash
            ceph osd unset nodeep-scrub
            ceph osd unset noout
            #在ceph_mon容器中执行
            ```
    - 容器中执行ceph命令没有回显，一直卡死

        ```
        解决方法: 检查ceph的public网络是否正常
        ```