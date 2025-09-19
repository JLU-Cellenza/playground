# Azure DRP Project: Setup with Azure Site Recovery (ASR)

## Project Overview
Implement a robust Disaster Recovery Plan (DRP) for critical workloads by leveraging Azure Site Recovery (ASR) to ensure business continuity and minimize downtime in case of disaster events.


## Objectives
- Enable seamless replication and failover of on-premises or cloud workloads to Azure using ASR.
- Ensure compliance with Recovery Time Objective (RTO) and Recovery Point Objective (RPO) requirements.
- Ensure complicance with budget constraints
- Iterate over the designed and partially built DRP platform done by NTT
- Test and document the DRP process for regular validation and audit readiness.

## Key Requirements
- Identify and prioritize critical workloads for protection.
- Clean the previsouly built platform.
- Set up Azure Site Recovery vault and configure replication policies.
- Plan network mapping and connectivity between primary and recovery sites.
- Automate failover and failback processes as much as possible.
- Organize with NTT for design, build and delivery.
- Schedule regular DR drills and document results.
- Ensure compliance with organizational and regulatory standards.

## Milestones
1. **Assessment & Planning**  
   - Define DR scope, technical target, feasibility and planning (Due: 09/19)
2. **ASR Setup & Configuration**  
   - Deploy ASR vault, configure replication (Due: 10/03)
3. **Network & Security**  
   - Implement network mappings, NSGs, and connectivity (Due: 10/10)
4. **Testing & Validation**  
   - Conduct DR drills, document outcomes (Due: 10/18)
5. **Go-Live & Monitoring**  
   - Finalize DRP, enable monitoring and alerting (Due: 10/31)

## Known Issues & Risks
- Initial design incompatibility with related costs.
- Cost overruns due to unoptimized replication/storage.
- Incomplete workload inventory may lead to gaps in DR coverage.
- Network misconfiguration could impact failover success.
- Insufficient testing may result in undetected issues during real disaster events.
- Hardcoded software configurations might result in non operational application.

## Action Items
- Prove that ASR will work for SQL Databases.
- Schedule target design presentation with NTT.
- Review Azure Site Recovery best practices.
- Orgnanize build phase with NTT.
- Destroy existing platform to reduce costs and start from fresh.
- Review network design.
- Describe DR triggering process with principal protagonists within NTT, Lemonway.
- Set up monitoring and alerting for replication health.
- Plan and execute first DR drill.

## References
- [Azure Site Recovery Overview](https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-overview)
- [ASR Best Practices](https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-best-practices)