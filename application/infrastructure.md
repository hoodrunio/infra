### Validator Infrastructure Details

**Hosting Strategy & Data Center Location**

At HoodRun, we prioritize decentralization and security in our validator infrastructure. To avoid over-concentration and potential single points of failure, we carefully select data centers and hosting providers with low ecosystem centralization risk. Our validator nodes primarily run on **bare-metal servers**, giving us full control over performance and security.

We currently operate with providers such as:

* **OVH** (EU-central, Warsaw)
* **FiberState**
* **Mevspace**
* **Cherry Servers**

This allows for geographic and provider-level redundancy. We can provision new dedicated machines on short notice when needed, enabling fast failover and scaling.

---

**Infrastructure & Security Architecture**

#### Zero-Trust Access (SSH)

All remote access is managed through **Tailscale / Tailnet**, a zero-trust networking solution. This ensures:

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

* **Remote Signing (Horcrux)**
  Where supported, we implement distributed remote signing using Horcrux. This ensures:

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
