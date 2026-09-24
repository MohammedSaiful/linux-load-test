# Linux Service Account & Load Testing observations

When the system was under load, I observed increased CPU and memory usage. During the stress tests, the system resources were consumed more heavily than during normal operation. I monitored the CPU, memory, disk/tmpfs usage, and running processes to see how the system behaved.

The system remained responsive during the test, but the resource usage increased according to the type of load being generated. This helped me understand how a Linux system behaves when its resources are under pressure.



-------------------------------------------------



In a real production environment, I would not directly run heavy stress tests on the live server because they could affect real users and services.

Instead, I would:

Perform load testing in a separate staging or testing environment.
Set resource limits so a test cannot consume all system resources.
Use monitoring tools such as Prometheus and Grafana to continuously monitor CPU, memory, disk, and network usage.
Configure proper alerting when resource usage reaches critical thresholds.
Use centralized logging so system and application logs can be analyzed easily.
Configure backups and recovery procedures before making major changes.
Use proper service accounts with only the permissions they need.
Use automated deployment and configuration management instead of making manual changes directly on production servers.
If necessary, use multiple servers or cloud scaling so increased traffic can be handled without taking the service down.

Overall, the assignment showed me how to safely create a service environment, generate controlled load, monitor resources, and clean up the environment. In production, I would focus much more on isolation, monitoring, resource limits, security, reliability, and preventing the load test from affecting real users.