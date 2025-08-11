# Slurm Mini Cluster (Docker Compose)

This project provides a minimal Slurm cluster (1 controller + 2 nodes) using Docker Compose, suitable for local development, testing, and learning Slurm job scheduling.

## Features
- Slurm controller and two compute nodes, all running in Docker containers
- Shared MUNGE authentication for secure Slurm operation
- Shared volume for job scripts and data
- Pre-configured with a simple `slurm.conf`

## Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)

## Getting Started

### 1. Clone the repository
```sh
git clone https://github.com/Drashko73/slurm-mini.git
cd slurm-mini
```

### 2. Build and start the cluster
```sh
docker-compose up --build
```
This will build the image and start three containers:
- `slurm-controller` (Slurm controller)
- `slurm-c1` (compute node 1)
- `slurm-c2` (compute node 2)

### 3. Accessing the containers
To open a shell in the controller:
```sh
docker exec -it slurm-controller bash
```
Or on a compute node:
```sh
docker exec -it slurm-c1 bash
```

### 4. Submitting and running jobs
Place your job scripts or data in the `slurm_shared/` directory on your host. This directory is mounted in all containers at `/slurm_shared`.

Example: Submit a simple job from the controller:
```sh
# Inside the controller container
srun -N1 -n1 hostname
# or
sbatch /slurm_shared/your_job_script.sh
```

### 5. Checking job and node status
```sh
sinfo      # Show node/partition status
squeue     # Show job queue
scontrol show nodes
```

## Configuration
- **Slurm config:** `config/slurm.conf` (edit to change cluster layout, resources, etc.)
- **Entrypoint script:** `entrypoint.sh` (handles MUNGE setup and Slurm startup)
- **Dockerfile:** Installs all dependencies and sets up the environment
- **docker-compose.yml:** Defines the cluster topology and shared volumes

## Stopping the cluster
```sh
docker-compose down
```

## Notes
- The cluster is for local/testing use only. Do not use in production.
- All nodes share `/slurm_shared` for easy data/job sharing.
- You can add more nodes by copying the `c1`/`c2` service blocks in `docker-compose.yml`.

## Troubleshooting
- If `gcc` is not found, ensure the image is rebuilt (`docker-compose build`).
- If jobs do not start, check `sinfo` and container logs for errors.

---

For more details, see the comments in each file.
