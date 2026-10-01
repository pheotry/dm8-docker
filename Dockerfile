FROM ubuntu:22.04 AS installer

ENV DEBIAN_FRONTEND=noninteractive

RUN groupadd dinstall -g 2001 && \
    useradd -G dinstall -m -d /home/dmdba -s /bin/bash -u 2001 dmdba && \
    chmod 1777 /tmp && \
    printf '%s\n' \
      'deb http://mirrors.aliyun.com/ubuntu jammy main restricted' \
      'deb http://mirrors.aliyun.com/ubuntu jammy-updates main restricted' \
      'deb http://mirrors.aliyun.com/ubuntu jammy-security main restricted' \
      > /etc/apt/sources.list && \
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=30 update && \
    apt-get install -y --no-install-recommends sudo tzdata && \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Shanghai

COPY DMInstall.bin /mnt/DMInstall.bin
COPY setup.xml /tmp/setup.xml

RUN chmod +x /mnt/DMInstall.bin && \
    sudo -u dmdba /mnt/DMInstall.bin -q /tmp/setup.xml

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN groupadd dinstall -g 2001 && \
    useradd -G dinstall -m -d /home/dmdba -s /bin/bash -u 2001 dmdba && \
    chmod 1777 /tmp && \
    printf '%s\n' \
      'deb http://mirrors.aliyun.com/ubuntu jammy main restricted' \
      'deb http://mirrors.aliyun.com/ubuntu jammy-updates main restricted' \
      'deb http://mirrors.aliyun.com/ubuntu jammy-security main restricted' \
      > /etc/apt/sources.list && \
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=30 update && \
    apt-get install -y --no-install-recommends sudo tzdata && \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Shanghai

COPY --from=installer /home/dmdba/ /home/dmdba/
COPY --from=installer /home/dmdba/dmdbms/bin/dm_svc.conf /etc/dm_svc.conf
COPY entrypoint.sh /entrypoint.sh

RUN printf '\nCHAR_CODE=(PG_UTF8)\n' >> /etc/dm_svc.conf

ENV DM_HOME=/home/dmdba/dmdbms
ENV PATH=$DM_HOME/bin:$DM_HOME/tool:$PATH
ENV LD_LIBRARY_PATH=/home/dmdba/dmdbms/bin
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN chmod +x /entrypoint.sh

USER root
EXPOSE 5236

ENTRYPOINT ["/entrypoint.sh"]
