# Netbird
> create secure private networks for your
>> NetBird is an open source platform consisting of a collection of components, responsible for handling peer-to-peer connections, tunneling, authentication, and network management
## On Cloud
- [Netbird](https://netbird.io/)
- [How NetBird works](https://docs.netbird.io/about-netbird/how-netbird-works)
- [Netbird App](https://app.netbird.io)
## Selfed Host
- [Netbird IPv9 App](https://netbird.ipv9.me/)
```

```
```
openssl rand -base64 32
```
```

```
```
docker run --rm -d \
 --hostname  \
 --cap-add=NET_ADMIN \
 -e NB_SETUP_KEY= \
 -e NB_PRESHARED_KEY=   \
 -v netbird-client:/etc/netbird \
 -e NB_MANAGEMENT_URL=https://netbird.ipv9.me \
 netbirdio/netbird:latest
```