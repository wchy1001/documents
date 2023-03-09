# Add a datastore in Trove

## prerequisite:

1. a develop environment, we reconmmand to use devstack.

2. Knowledge of python language

3. Knowledge of Openstack

4. Knowledge of the database 


## Add a configuration template

refer to [other database template](https://github.com/openstack/trove/tree/master/trove/templates)， Add a new configuration template


## Add a datastore driver

refer to [mariadb driver](https://github.com/openstack/trove/tree/master/trove/guestagent/datastore/mariadb)  to implements a new driver. we  also need to build backup image [at here](https://github.com/openstack/trove/tree/master/trove/backup)

## CI

Add CI tests [at here](https://github.com/openstack/trove-tempest-plugin/blob/master/trove_tempest_plugin/services/client.py)

## reference

[this patch](https://github.com/openstack/trove/commit/d1af33f17b0994ac1d0ca5acca91f2f29bc82ce9#diff-31eaffdd17f8365edb00b99ad25867f4bd6870494ff4d5c93c6d15fc6edbb364) may helps you a lot.