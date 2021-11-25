Stardust
=====

Stardust is a FCM/APNS pooling push application. With configuration you can start X number of connections to connect for each FCM account or APNS cert.

To start APNS:
```erlang
stardust_apns:start(KeyId, TeamId, P8).
```

This  will start a pool with 5 processes that will send apns push to apple.

To send a synchronous push where you want to know the answer:

```erlang
stardust_apns:send(KeyId, BundleId, Message, DeviceToken, ApnsType).
```

To send a asynchronous push where you don't want to know the answer:
```erlang
stardust_apns:async_send(KeyId, BundleId, Message, DeviceToken, ApnsType).
```

To start FCM:
```erlang
stardust_fcm:start(ServiceAccount).
```

Send in ServiceAccount as a map and stardust_fcm will start a pool to handle fcm push to google.

To send syncronous push to FCM:
```erlang
stardust_fcm:send(ProjectId, FCMobj).
```

To send asyncronous push to FCM:
```erlang
stardust_fcm:async_send(ProjectId, FCMobj).
```
