# Anypoint identity setup

Two registrations were created in the current Valion demo tenant on 20 October 2026:

| Registration | Purpose | Configuration |
|---|---|---|
| `fzag-anypoint-sso` | Anypoint Cloud OIDC login | Single tenant, authorization code, delegated OpenID/profile/email permissions, private client secret in the existing Key Vault |
| `fzag-demo-api` | Protected demo API resource | Single tenant, v2 access tokens, API identifier URI, delegated `Flights.Read` / `Flights.Write` scopes, application `Flights.Read.All` / `Flights.Write.All` roles |

The SSO client secret is stored as `anypoint-sso-client-secret` in Key Vault `kv-fzaginterop261019`; it is not in Git. Environment-specific copy/paste configuration was delivered separately to the user.

The user-provided Anypoint EU callback is now registered as a Web redirect URI and verified in Entra. Pending: a live Anypoint SSO login, team/permission mapping, any tenant-required consent, API calling-client registration/grants, gateway policy configuration and end-to-end tests. No callback was guessed; no tenant-wide admin consent or application-role grants were made. No paid identity feature or extra cluster was enabled.

Anypoint SSO and API authorization are separate. API enforcement must validate access-token signature, issuer, audience, lifetime and `scp`/`roles` permissions. A registered API resource alone does not secure a running API.

Sources: [Anypoint OIDC SSO](https://docs.mulesoft.com/access-management/conf-openid-connect-task), [Mule JWT policy](https://docs.mulesoft.com/mule-gateway/policies-included-jwt-validation), [Entra claim validation](https://learn.microsoft.com/en-us/entra/identity-platform/claims-validation).
