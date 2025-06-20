### How to Add a New OpenID Connect Provider to Authelia

1. **Follow the Official Integration Guide**  
   Refer to the official Authelia documentation for OpenID Connect integration:  
   [Authelia OpenID Connect Integration Guide](https://www.authelia.com/integration/openid-connect/)

2. **Update the Configuration**  
   - Add the new provider's configuration section to `config/configuration.yml`.
   - For the client secret, reference the secret file at:  
     `$VOLUMEDIR/authelia/secrets/[PROVIDER]_client_secret`  
     (e.g., `portainer_client_secret`).  
   - The secret file should contain the hashed client secret.

3. **Generate and Store the Client Secret**  
   - To generate a client identifier or client secret, follow the instructions here:  
     [How to Generate a Client Identifier or Client Secret](https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#how-do-i-generate-a-client-identifier-or-client-secret)
   - Store the **hashed** client secret in the secret file as described above.

4. **Update the Client Application**  
   - Configure your client application (e.g., Portainer) with the **cleartext** client secret.

5. **Restart Authelia**  
   - Recreate or restart the Authelia container to apply the changes.

