# Challenges faced and resolutions

### Problem
The app had an outdated version of node (node:14) that caused compatibility issues with the pg dependency.
### Solution 
Updated the Docker base image to node:lts-trixie-slim and rebuilt the image successfully.

---

### Problem
The app tried to connect to PostgreSQL before the db was ready, resulting in ECONNREFUSED
### Solution 
Added a PostgreSQL healthcheck and changed depends_on in compose file to wait for service_healthy before starting the API.

---

### Problem
Actions couldntt configure AWS creds
### Solution
The GitHub Actions OIDC trust policy was initially based on the legacy repository-name subject format. Because the repository was created after GitHub's immutable OIDC subject rollout, the trust policy was updated to use the owner and repository IDs.