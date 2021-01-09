FROM ubuntu:18.04

RUN apt-get update && \
 apt-get install -y --no-install-recommends \
     wireguard-tools iptables nano net-tools procps openresolv inotify-tools \
     bc build-essential curl dkms git gnupg ifupdown iproute2 iptables iputils-ping \
     jq libc6 libelf-dev net-tools openresolv vim && \
 apt-get clean


EXPOSE 51820/udp

WORKDIR /scripts
ENV PATH="/scripts:${PATH}"

# Use iptables masquerade NAT rule
ENV IPTABLES_MASQ=1

# Watch for changes to interface conf files (default off)
ENV WATCH_CHANGES=0

COPY ./root /
RUN chmod 755 /scripts/*

CMD ["run"]
