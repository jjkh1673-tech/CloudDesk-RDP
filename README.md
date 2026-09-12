# CloudDesk RDP

A small Linux RDP workspace for Railway.

CloudDesk is deliberately built for one simple workflow: use Firefox for cloud storage and web work, use the terminal for file operations and command-line tools, and keep everything else out of the base desktop.

## What is included

- Firefox ESR — the main work application
- XFCE — lightweight desktop/session
- Terminal — file operations, downloads, uploads and temporary tools
- Thunar — lightweight graphical file manager
- Plank — small macOS-inspired vertical dock on the left
- XRDP + Xorg — Windows Remote Desktop access
- ZIP / 7-Zip and common file utilities
- `curl` / `wget`
- `nano`, `less`, `htop` and basic network tools
- `sudo` for installing extra software when required

The base image intentionally does **not** include a full Ubuntu desktop, LibreOffice, media suites, IDEs, databases, Redis or other background-heavy services.

## Why it is minimal

The target is a useful desktop on a small Railway service, including **1 GB RAM and 1 vCPU** as the design target.

This is a target, not a performance guarantee. Modern websites and especially Firefox can use substantial memory and CPU. If the actual workload exceeds the available Railway resources, increasing the service resources is the correct fix.

XFCE is chosen because it is a lightweight desktop environment; Ubuntu also provides XFCE packages for Ubuntu 24.04. Railway runs the project as a container, so avoiding a full desktop stack and unnecessary background services is important.

## Login

```text
Username: ubuntu
Password: 1122
```

For a non-public deployment, change the password using a Railway variable:

```text
RDP_PASSWORD=your-strong-password
```

Do not publish a real password in a public GitHub repository.

## Deploy to Railway

### 1. Put the files in GitHub

The repository root must contain:

```text
Dockerfile
start.sh
README.md
```

The file must be named exactly `Dockerfile` with a capital `D`.

### 2. Create the Railway service

1. Open Railway.
2. Create a new project.
3. Choose **Deploy from GitHub repo**.
4. Select this repository.
5. Wait for the Docker build and deployment.

Railway automatically detects a root-level file named `Dockerfile`.

### 3. Expose RDP

After the service is running:

1. Open the service in Railway.
2. Open **Settings**.
3. Open **Networking**.
4. Create a **TCP Proxy**.
5. Set the internal port to:

```text
3389
```

Railway will provide a TCP hostname and port.

### 4. Connect from Windows

Open **Remote Desktop Connection** (`mstsc`).

Enter the Railway TCP address:

```text
HOST:PORT
```

Log in:

```text
Username: ubuntu
Password: 1122
```

## Keep files after redeploys

Container storage should not be treated as permanent storage.

If downloaded/uploaded files must survive redeploys and container replacement:

1. Add a Railway Volume.
2. Mount it at:

```text
/home/ubuntu/Workspace
```

Use that directory for important files.

Example:

```text
/home/ubuntu/Workspace/
├── Downloads/
├── Uploads/
└── Projects/
```

Railway Volumes persist data across deploys and restarts.

## Extra applications

Extra applications are intentionally **not** installed by default.

This is a deliberate design choice: every permanent application increases the image size and may add processes, libraries or background services. The base desktop is meant to stay small.

When a task needs another application, install it from Terminal:

```bash
sudo apt update
sudo apt install PACKAGE_NAME
```

Example:

```bash
sudo apt install imagemagick
```

### Temporary installation

A package installed manually while the container is running is useful for one-off work.

It may disappear when the container is rebuilt or replaced.

### Permanent installation

If an application becomes part of your normal workflow:

1. Add its package name to the `apt-get install` section in `Dockerfile`.
2. Commit the change to GitHub.
3. Redeploy on Railway.

This keeps the base image intentional instead of turning it into a large general-purpose desktop.

## File operations

List files:

```bash
ls -lah
```

Move:

```bash
mv old-name new-name
```

Copy:

```bash
cp file /home/ubuntu/Workspace/
```

Extract:

```bash
unzip file.zip
```

Create a ZIP:

```bash
zip -r archive.zip folder/
```

Disk usage:

```bash
df -h
```

Memory:

```bash
free -h
```

Processes:

```bash
htop
```

## Cloud-storage workflow

The intended workflow is simple:

1. Open Firefox from the left dock.
2. Open your cloud-storage service.
3. Upload or download files.
4. Keep important files in `/home/ubuntu/Workspace`.
5. Use Terminal or Thunar when files need to be renamed, moved, extracted or processed.

No separate cloud-storage client is required for normal browser-based services.

## Performance

CloudDesk disables desktop compositing and unnecessary visual effects.

For best performance:

- Keep unnecessary Firefox tabs closed.
- Avoid unnecessary browser extensions.
- Use one cloud-storage session instead of several duplicate tabs/windows.
- Use Terminal for bulk file operations.
- Keep important data on a Railway Volume.
- Do not add Redis/PostgreSQL or other services unless the actual workload needs them.

Check the service from Terminal:

```bash
free -h
```

```bash
htop
```

If CPU or RAM is consistently near the service limit, the limitation is the available Railway compute rather than an unused desktop application.

## Project structure

```text
CloudDesk-RDP/
├── Dockerfile
├── start.sh
└── README.md
```

## License

Add the license you want to use before publishing the repository.
