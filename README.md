# 启动容器

```bash
docker-compose up -d --build
```

# mysql 操作

<details>
<summary><b>master 操作</b></summary>

### 1、进入 `mysql-master` 容器。

```bash
docker exec -it mysql-master sh
```

### 2、查看容器 `ip`

```bash
cat /etc/hosts
```

### 3、执行以下命令，创建用于同步的用户账号 `rep`，密码是 `888888`

```bash
mysql> CREATE USER 'rep'@'%' IDENTIFIED BY '888888';
Query OK, 0 rows affected (0.16 sec)
```

### 4、执行以下命令，授权用户同步

```bash
mysql> GRANT REPLICATION SLAVE ON *.* TO 'rep'@'%';
Query OK, 0 rows affected (1.01 sec)
```

### 5、执行以下命令刷新权限

```bash
mysql> flush privileges;
Query OK, 0 rows affected (0.06 sec)
```

### 6、执行命令 `show master status`; 查看同步状态，如下，请关注下表的 `File` 和 `Position` 这两个字段的值 

```bash
mysql> show master status;
+------------------+----------+--------------+-------------------------------------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB                                | Executed_Gtid_Set |
+------------------+----------+--------------+-------------------------------------------------+-------------------+
| mysql-bin.000002 |      745 |              | information_schema,mysql,performance_schema,sys |                   |
+------------------+----------+--------------+-------------------------------------------------+-------------------+
1 row in set (0.01 sec)
```

至此，master已经设置成功，接下来设置slave吧，

</details>

<details>
<summary><b>slave 操作</b></summary>

### 1、进入 `mysql-slave` 容器。

```bash
docker exec -it mysql-slave sh
```

### 2、设置主从同步的参数

```bash
CHANGE MASTER TO MASTER_HOST='192.168.64.2', \
MASTER_USER='rep', \
MASTER_PASSWORD='888888', \
MASTER_LOG_FILE='mysql-bin.000002', \
MASTER_LOG_POS=745;
```

```mysql
mysql> CHANGE MASTER TO MASTER_HOST='192.168.64.2', \
FILE    -> MASTER_USER='rep', \
    -> MASTER_PASSWORD='888888', \
    -> MASTER_LOG_FILE='mysql-bin.000002', \
    -> MASTER_LOG_POS=745;
Query OK, 0 rows affected, 2 warnings (0.78 sec)
```

> MASTER_HOST 是 master 的IP地址；
> MASTER_USER 和 MASTER_PASSWORD 是 master 授权的同步账号和密码；
> MASTER_LOG_FILE 是 master 的 bin log 文件名；
> MASTER_LOG_POS 是 bin log 同步的位置；

### 3、在MySQL命令行执行 `start slave`;启动同步

```bash
mysql> start slave;
Query OK, 0 rows affected (0.07 sec)
```

### 4、在MySQL命令行执行show slave status\G查看同步状态

```bash
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.64.2
                  Master_User: rep
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 745
               Relay_Log_File: 40fcf9eae6b2-relay-bin.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 745
              Relay_Log_Space: 534
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: 01784cbe-746f-11ed-9ac0-0242c0a84002
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```

检查以上信息中的 `Slave_IO_Running` 和 `Slave_SQL_Running` 两个字段的值，如果都是Yes就表示同步启动成功，否则代表启动失败，`Slave_SQL_Running_State` 字段会说明失败原因；

至此，MySQL主从同步已经完成，接下来一起验证一下吧。

</details>

# 遇到的问题

## 1、ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)

解决方法：删除 `/var/run/mysqld/mysqld.sock`,重启容器