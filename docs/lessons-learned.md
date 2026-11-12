# Lessons learned — feldmarkt-migration

Takeaways from designing this blueprint. This is not a lived cutover postmortem: nothing from this repository has been applied to a cloud account.

---

## What worked in the design

- Naming the repo a blueprint (not a silent scaffold) makes the interview line honest: same class of work as on the job, encoded here without publishing an employer system.
- Keeping MGN as the rehost path and refusing Ansible day-2 estate management (D1 / D8) avoids the common “Terraform + MGN + harden with Ansible” story that undoes “lift as-is.”
- Encoding Sunday order in both prose and Ansible runbooks (freeze → proofs → validate → DNS) gives operators a single checklist.
- Separating nonprod and prod RDS security groups closes a real blast-radius hole that a shared node SG would leave open.

## What we corrected while writing

- Prod health cannot gate sync if pods only exist after sync. Order is row check → sequences → manual prod sync → health → DNS.
- DMS defaults would drop schema and truncate LOBs. The task is `DO_NOTHING`, full LOB, validation on, with schema-only load first.
- Digest CI must keep the `sha256:` field from `docker push`, not the size token on that line.
- Rollback must scale prod to 0 and stop DMS before DNS returns to the colo.

## Limits we accept (and would change for a lived run)

- Placeholders remain until a real inventory and landing-zone IDs exist.
- VPN is required and not Terraform here.
- Wave 3 stays description only.
- A throwaway apply (roadmap L1) would be needed before claiming cutover screenshots.

## Related

- Tradeoffs on the front page: [README.md](../README.md)
- Decisions: [decisions.md](decisions.md)
- Roadmap: [ROADMAP.md](../ROADMAP.md)
