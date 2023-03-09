# openstack pecan web framework

## Introduce

`pecan` 是一个轻量级的 api 服务，遵循restful api风格，不提供数据库的链接等功能，需要配合 `sqlalchemy` 使用完成数据库的增删改查， pecan 同时提供了参数的校验，参数的校验配合`wsme`来使用，pecan通过controller来封装后端的对象。起始点是一个`root controller`.

## openstack-zun Code

1. `ROOT Controller`


```python
# path: zun.api.controllers.root.RootController
class RootController(rest.RestController):

    _versions = ['v1']
    """All supported API versions"""

    _default_version = 'v1'
    """The default API version"""

    v1 = v1.Controller()
```
>所有的 endpoint下面的 /v1 会走到v1.Controller()

1. `V1 Controller`

```python
    # path: zun/api/controllers/v1/__init__.py
    class Controller(controllers_base.Controller):
        """Version 1 API controller root."""

        services = zun_services.ZunServiceController()
        containers = container_controller.ContainersController()
        images = image_controller.ImagesController()
        networks = network_controller.NetworkController()
        hosts = host_controller.HostController()
        availability_zones = a_zone.AvailabilityZoneController()
        capsules = capsule_controller.CapsuleController()
        quotas = quotas_controller.QuotaController()
        quota_classes = quota_classes_controller.QuotaClassController()
        registries = registries_controller.RegistryController()

        @pecan.expose('json')
        def get(self):
            return V1.convert()
```
接下来所有的`v1/services`的请求会到`ZunServiceController()`中处理，其他的也是类似，每一个Controller里面的结构都是一样的，可以自定义方法，如 `_custon_actions`, `_lookup`方法

1. `_lookup` methond

_lookup是在某个特定字符结尾的时候，重新定义到别的controller上，实现增删改查，以octavia为例

需要请求的api如下: `/v2/lbaas/listeners/{listener_id}/stats`

```python
    @pecan_expose()
    def _lookup(self, id, *remainder):
        """Overridden pecan _lookup method for custom routing.

        Currently it checks if this was a stats request and routes
        the request to the StatsController.
        """
        if id and remainder and remainder[0] == 'stats':
            return StatisticsController(listener_id=id), remainder[1:]
        return None
```

1. `_custon_actions` methond

默认的restful方法不能满足的时候，需要重新定义到新的方法.


```python
# path: /v1/container/<id>/action
class ContainersController(base.Controller):
    """Controller for Containers."""

    _custom_actions = {
        'start': ['POST'],
        'stop': ['POST'],
        'reboot': ['POST'],
        'rebuild': ['POST'],
        'pause': ['POST'],
        'unpause': ['POST'],
        'logs': ['GET'],
        'execute': ['POST'],
        'execute_resize': ['POST'],
        'kill': ['POST'],
        'rename': ['POST'],
        'attach': ['GET'],
        'resize': ['POST'],
        'resize_container': ['POST'],
        'top': ['GET'],
        'get_archive': ['GET'],
        'put_archive': ['POST'],
        'stats': ['GET'],
        'commit': ['POST'],
        'add_security_group': ['POST'],
        'network_detach': ['POST'],
        'network_attach': ['POST'],
        'network_list': ['GET'],
        'remove_security_group': ['POST']
    }

    container_actions = ContainersActionsController()

    @pecan.expose('json')
    @exception.wrap_pecan_controller_exception
    def get_all(self, **kwargs):
        """Retrieve a list of containers.

        """
        context = pecan.request.context
        policy.enforce(context, "container:get_all",
                       action="container:get_all")
        return self._get_containers_collection(**kwargs)

```

1. 默认的restful请求方法

默认的controller请求如下 [link](https://pecan.readthedocs.io/en/latest/rest.html?highlight=get_one#url-mapping)


By default, RestController routes as follows:

|Method|Description|Example Method(s) / URL(s)|
|---|---|---|
|get_one|Display one record.|GET /books/1|
|get_all|Display all records in a resource.|GET /books/|
|post|Create a new record.|POST /books/|
|put|Update an existing record.|PUT /books/1|
|delete|Delete an existing record.|DELETE /books/1|
