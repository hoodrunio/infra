### Validator Infrastructure Details

At **HoodRun**, our validator infrastructure is designed with three guiding principles: **security, redundancy, and rapid failover**.
We operate bare-metal servers across multiple independent providers in Europe and US, with the ability to scale globally. Our setup ensures:

* **>99.9% uptime** with proactive monitoring and automated remediation
* **Fast recovery** backup nodes can be spun up in minutes
* **Zero-trust access** no open SSH ports, all identity-based connections
* **Key security** remote signing (Horcrux for cosmos-sdk based chains) and Vault-based key management

This architecture allows us to maintain highly reliable validators while minimizing risks of downtime, slashing, or key compromise.

**Hosting Strategy & Data Center Location**

At HoodRun, we prioritize decentralization and security in our validator infrastructure. To avoid over-concentration and potential single points of failure, we carefully select data centers and hosting providers with low ecosystem centralization risk. Our validator nodes primarily run on **bare-metal servers**, giving us full control over performance and security.

We currently operate with providers such as:

* **OVH** (EU-central, Warsaw)
* **FiberState** (US)
* **Mevspace** (EU)
* **Cherry Servers** (US-Chicago)

This allows for geographic and provider-level redundancy. We can provision new dedicated machines on short notice when needed, enabling fast failover and scaling.

---

**Infrastructure & Security Architecture**

#### Zero-Trust -Like- Access (SSH)

All remote access is managed through **Tailscale / Tailnet**, a zero-trust like networking solution. This ensures:

* No open SSH ports on the public internet
* Encrypted, identity-based access control
* Real-time revocation and auditability of device access

#### Monitoring & Alerting

We employ a hybrid monitoring system combining open-source and in-house tools:

* **Real-time alerts via PagerDuty**, integrated with all critical health checks
* Custom scripts for validator health, performance, and liveness tracking
* Automatic escalation for critical issues (e.g., jailed status, missed blocks)

---

**Validator Security Configuration**

* **Remote Signing**
  Where supported, we implement distributed remote signing services. This ensures:

  * The private key is never fully present on any single node
  * Signing operations are securely coordinated across multiple nodes
  * Seamless failover and enhanced resistance to key compromise

* **Firewall & Network Isolation**

  * Only essential ports are exposed; P2P traffic is tightly filtered
  * Validator nodes are isolated in **private networks**, only accessible by whitelisted sentry nodes
  * All non-critical traffic is blocked by default (default-deny policy)

* **IP Whitelisting**

  * Critical components such as validator RPCs and remote signing endpoints are protected using strict IP whitelisting rules

* **Key Backup & Secret Management**

  * **HashiCorp Vault** is used to securely store and backup validator consensus keys
  * Access to Vault is tightly controlled and audited

---

**Redundancy & Recovery**

* We maintain cold spares and snapshot-based recovery systems for rapid redeployment
* Infrastructure-as-code and automated configuration tools enable us to spin up replacement nodes in minutes
* All services are monitored 24/7, with proactive remediation scripts in place
