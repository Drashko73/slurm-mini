FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      gcc-11 g++-11 \
      slurm-wlm slurmctld slurmd \
      munge libmunge2 \
      procps ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100

# Prepare MUNGE dirs with sane base ownership; entrypoint will enforce again
RUN mkdir -p /var/run/munge /var/lib/munge /var/log/munge /etc/munge && \
    chown munge:munge /var/run/munge /var/lib/munge && \
    chmod 755 /var/run/munge && chmod 700 /var/lib/munge && \
    chown root:root /var/log/munge && chmod 700 /var/log/munge && \
    chown root:root /etc/munge && chmod 755 /etc/munge

# Add Slurm config
COPY config/slurm.conf /etc/slurm/slurm.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV ROLE=node
CMD ["/entrypoint.sh"]