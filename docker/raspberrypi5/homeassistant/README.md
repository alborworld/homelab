## OIDC Integration

The HACS [OIDC Integration for Home Assistant](https://github.com/christiaangoossens/hass-oidc-auth) is enabled. This allows Single Sign-On (SSO) with Pocket ID or any other OIDC provider.

### Re-enableing default login

If you are locked out and need to restore the default login method:

1. Edit the following file:

    `$VOLUMEDIR/homeassistant/configuration.yaml`

2. Set the following option:

    `block_login: false`. 

3. Restart Home Assistant for the changes to take effect.
