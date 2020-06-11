# 数据库的常见问题

1. 三个mariadb节点掉电的时候，必然会出现数据库异常的修复办法。
    - 步骤一：先查看各个控制节点safe_to_bootstrap

        ```bash
        ansible -i ~/multinode control -m shell -a 'cat /var/lib/docker/volumes/mariadb/_data/grastate.dat|grep safe_to_bootstrap'
        #如果有节点值为1，直接写入下面mariadb_recover_inventory_name处，然后修复，如果没有，手动去修改一个节点的值为1，再修复
        ```
    - 步骤二: 停掉所有容器

        ```bash
        ansible -i multinode control -m shell -a 'docker stop mariadb'
        ```
    - 步骤三：执行修复脚本

        ```bash
        kolla-ansible -i /root/multinode mariadb_recovery -e mariadb_recover_inventory_name=control02
        #control02为步骤二里面得到的主机
        ```
    - 步骤四: 手动登录测试

        ```bash
        mysql -uroot -h<your vip address> -p<your password>
        #见下面的内容
        ```
2. 数据库查看集群状态
    - 获取数据库root密码

        ```bash
        [root@openstack ~]# grep ^database /etc/kolla/passwords.yml
        database_password: M3crDV1bZjEfYz4BpJykplV91uezwFCPRgUI9lov
        ```
    - 获取vip地址

        ```bash
        [root@openstack ~]# grep vip_address /etc/kolla/globals.yml
        kolla_internal_vip_address: "192.168.1.25"
        ```
    - 进入mariadb容器

        ```bash
        [root@openstack ~]# docker exec -it -u root mariadb bash
        ```
    - 登录数据库

        ```bash
        (mariadb)[root@openstack /]# mysql -uroot -h<your vip address> -p<your password>
        ```
    - 查看集群信息

        ```sql
        show status like "%wsrep%";
        show status like "wsrep_cluster_size";
        #查看集群成员个数
        ```
3. 在宿主机上查看mariadb的log

    ```bash
    [root@openstack ~]# tailf /var/lib/docker/volumes/kolla_logs/_data/mariadb/mariadb.log
    ```
4. 关于慢查询
    - 步骤一: 查看当前慢查询状态

        ```sql
        MariaDB [nova]> show variables like 'slow_query%';
        +---------------------+--------------------+
        | Variable_name       | Value              |
        +---------------------+--------------------+
        | slow_query_log      | OFF                |
        | slow_query_log_file | openstack-slow.log |
        +---------------------+--------------------+
        2 rows in set (0.00 sec)

        MariaDB [nova]> show variables like 'long_query_time';
        +-----------------+-----------+
        | Variable_name   | Value     |
        +-----------------+-----------+
        | long_query_time | 10.000000 |
        +-----------------+-----------+
        1 row in set (0.00 sec)
        ```
    - 步骤二：如果没有开启慢查询，则开启并设置慢查询时间（1秒）

        ```sql
        MariaDB [nova]> set global slow_query_log='ON';
        Query OK, 0 rows affected (0.02 sec)

        MariaDB [nova]> set global long_query_time=1;
        Query OK, 0 rows affected (0.01 sec)
        ```
    - 步骤三: 测试

        ```sql
        MariaDB [nova]> select sleep(2);
        ```
    - 查找日志

        ```bash
        tailf /var/lib/mysql/openstack-slow.log
        #提取sql语句
        ```
    - 查看执行计划

        ```
        MariaDB [(none)]> explain <your slow sql>
        ```
    - 关闭慢查询

        ```sql
        MariaDB [(none)]> set global slow_query_log='off';
        ```
