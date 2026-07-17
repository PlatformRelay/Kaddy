# Gridscale hiring exercise — Platform Engineer

Welcome to the platform engineering hiring exercise. Your task is to set up a Caddy web
server and implement basic application monitoring using Prometheus.

## Task description

As a platform engineer, you will often be responsible for deploying and maintaining reverse
proxies and ensuring their performance and reliability. In this exercise, you will demonstrate
your ability to:

- Install and configure a Caddy web server
- Implement basic monitoring for the web server and any hosted applications using Prometheus
- Implement a basic alerting pipeline

## Lab access

Register at the Gridscale lab cloud panel to get access:

**https://lab.gridscale.cloud/Access/signup**

Feel free to create as many VMs and resources as you need for this exercise.

Your lab account may take a few hours to activate. We will notify you by email when it is ready.

## Core requirements

- Install Caddy on a Linux-based system of your choice
- Configure Caddy to serve a sample web application (any simple HTML/CSS page is fine; the
  default Caddy page is also sufficient)
- Set up Prometheus to monitor the performance of the Caddy server and the web application
- Configure Prometheus to collect basic metrics such as HTTP response codes, request
  latency, and server uptime
- Ensure Prometheus scrapes metrics from Caddy at regular intervals
- Implement basic alerting in Prometheus based on predefined thresholds (for example,
  when HTTP requests exceed a threshold or the server goes down)
- **Bonus points:** automate installation and configuration with infrastructure as code
  (Terraform, Ansible, Kubernetes, or any IaC tool of your choice)

## Core deliverables

- Documentation outlining the steps you took to install and configure Caddy and Prometheus
- Configuration files for Caddy and Prometheus
- Screenshots or logs demonstrating successful monitoring of the web server, application
  metrics, and alerting in Prometheus
- Code that installs and configures the infrastructure and applications

---

## Optional task — Nginx reverse proxy

Set up an additional Nginx server and configure Caddy as a reverse proxy.

### Requirements

- Provision an additional Linux VM
- Install and configure Nginx to serve a simple "Hello World" page
- Configure Caddy to distribute incoming requests between the Caddy web server and the
  Nginx server (for example, path-based routing or load balancing)
- Ensure Caddy is properly configured to handle traffic

### Deliverables

- Documentation detailing the setup and configuration of the Nginx server and Caddy reverse
  proxy
- Configuration files for Caddy
- Evidence demonstrating successful routing of requests to both the Caddy and Nginx servers
  through Caddy

### Bonus

- Configure health checks in Caddy for fault tolerance
- Configure SSL termination and encryption for secure communication between clients and the
  reverse proxy

This optional task is an opportunity to showcase skills in managing multiple server instances
and configuring more complex networking setups.

---

## Note

If you encounter questions or challenges during the exercise, reach out for assistance. Setting
up and configuring servers can be complex, and we are here to support you.

Our primary interest is your problem-solving approach and thought process. Do not stress if
you cannot complete every aspect perfectly. Your willingness to tackle challenges and seek
help when needed are valuable indicators of your potential as a platform engineer.

Happy coding — we look forward to seeing your solutions.
