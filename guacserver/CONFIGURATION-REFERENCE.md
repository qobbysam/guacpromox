# Guacamole Configuration Reference

This document explains all configuration options available in the Docker Compose setup, based on the [official Guacamole configuration documentation](https://guacamole.apache.org/doc/gug/configuring-guacamole.html).

---

## Overview

When using Docker, Guacamole configuration is done through **environment variables** instead of `guacamole.properties` file. Environment variable names are derived from property names by:
1. Converting to UPPERCASE
2. Replacing dashes (`-`) with underscores (`_`)

For example: `api-session-timeout` → `API_SESSION_TIMEOUT`

---

## Environment Variables in docker-compose.yml

### Connection to guacd

These are **required** for Guacamole to connect to the guacd daemon:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `GUACD_HOSTNAME` | Hostname or IP of guacd daemon | `localhost` | Yes |
| `GUACD_PORT` | Port guacd is listening on | `4822` | Yes |

**Current Configuration:**
```yaml
GUACD_HOSTNAME: guacd  # Uses Docker service name
GUACD_PORT: 4822       # Standard guacd port
```

---

### PostgreSQL Database Connection

These are **required** for database authentication:

| Variable | Description | Required |
|----------|-------------|-----------|
| `POSTGRESQL_HOSTNAME` | PostgreSQL server hostname | Yes |
| `POSTGRESQL_DATABASE` | Database name | Yes |
| `POSTGRESQL_USER` | Database username | Yes |
| `POSTGRESQL_PASSWORD` | Database password | Yes |
| `POSTGRESQL_AUTO_CREATE_ACCOUNTS` | Auto-create users from external auth | No |

**Note:** Older versions used `POSTGRES_*` prefix, but `POSTGRESQL_*` is the current standard.

**Current Configuration:**
```yaml
POSTGRESQL_HOSTNAME: guacamole-db
POSTGRESQL_DATABASE: guacamole_db
POSTGRESQL_USER: guacamole_user
POSTGRESQL_PASSWORD: ${POSTGRES_PASSWORD:-ChangeMePostgresPassword123!}
POSTGRESQL_AUTO_CREATE_ACCOUNTS: "true"
```

---

### Session and API Configuration

| Variable | Property Name | Description | Default | Current |
|----------|---------------|-------------|---------|---------|
| `API_SESSION_TIMEOUT` | `api-session-timeout` | Session timeout in minutes (0 = unlimited) | 60 | 360 |
| `API_MAX_REQUEST_SIZE` | `api-max-request-size` | Max HTTP request size in bytes (0 = unlimited) | 2097152 (2MB) | 10485760 (10MB) |

**Current Configuration:**
```yaml
API_SESSION_TIMEOUT: 360           # 6 hours (longer for remote desktop sessions)
API_MAX_REQUEST_SIZE: 10485760     # 10MB (for file transfers)
```

**Explanation:**
- **API_SESSION_TIMEOUT**: How long authentication tokens remain valid without activity. Set to 360 minutes (6 hours) to allow long remote desktop sessions without re-authentication.
- **API_MAX_REQUEST_SIZE**: Maximum size of HTTP requests. Increased to 10MB to support larger file transfers via the web interface.

---

### Language Configuration

| Variable | Property Name | Description |
|----------|---------------|-------------|
| `ALLOWED_LANGUAGES` | `allowed-languages` | Comma-separated list of allowed language codes (e.g., "en,de,fr") |

**Current Configuration:**
```yaml
# ALLOWED_LANGUAGES: en  # Commented out - all languages allowed by default
```

**To restrict to specific languages:**
```yaml
ALLOWED_LANGUAGES: en,de,fr  # Only English, German, and French
```

---

### Environment Properties

| Variable | Property Name | Description |
|----------|---------------|-------------|
| `ENABLE_ENVIRONMENT_PROPERTIES` | `enable-environment-properties` | Enable environment variable configuration (should be "true" for Docker) |

**Current Configuration:**
```yaml
ENABLE_ENVIRONMENT_PROPERTIES: "true"  # Required for Docker setup
```

This allows Guacamole to read configuration from environment variables instead of requiring a `guacamole.properties` file.

---

## guacd Configuration

The guacd daemon is configured via command-line arguments in the Docker Compose file:

**Current Configuration:**
```yaml
command: ["-b", "0.0.0.0", "-l", "4822", "-L", "info"]
```

### Command-Line Options

| Option | Parameter | Description | Current Value |
|--------|-----------|-------------|---------------|
| `-b` | `HOST` | Bind host/address | `0.0.0.0` (all interfaces) |
| `-l` | `PORT` | Bind port | `4822` (standard port) |
| `-L` | `LEVEL` | Log level | `info` |

**Log Levels:**
- `trace` - Most verbose
- `debug` - Debug information
- `info` - Informational messages (default, recommended)
- `warning` - Warnings only
- `error` - Errors only

**Why `0.0.0.0`?**
- guacd needs to be accessible from the guacamole container
- Binding to `localhost` would only allow local connections
- `0.0.0.0` allows connections from other Docker containers on the same network

---

## Additional Configuration Options

### Available but Not Currently Configured

These options can be added to the `environment:` section if needed:

#### Security Options

| Variable | Property Name | Description | Default |
|----------|---------------|-------------|---------|
| `TRUSTED_PROXIES` | `trusted-proxies` | Comma-separated list of trusted proxy IPs | None |
| `DENIED_PROXIES` | `denied-proxies` | Comma-separated list of denied proxy IPs | None |

#### SSL/TLS Configuration (for guacd)

If you need SSL encryption between Guacamole and guacd:

| Variable | Property Name | Description |
|----------|---------------|-------------|
| `GUACD_SSL` | Set via guacd command | Enable SSL encryption |

**Example (not in current setup):**
```yaml
guacd:
  command: ["-b", "0.0.0.0", "-l", "4822", "-C", "/path/to/cert.crt", "-K", "/path/to/key.key"]
```

#### Database Connection Pooling

| Variable | Property Name | Description | Default |
|----------|---------------|-------------|---------|
| `POSTGRESQL_MAX_CONNECTIONS` | `postgresql-max-connections` | Max database connections per user | 1 |
| `POSTGRESQL_MAX_IDLE_CONNECTIONS` | `postgresql-max-idle-connections` | Max idle connections | 10 |
| `POSTGRESQL_MAX_RECONNECT_ATTEMPTS` | `postgresql-max-reconnect-attempts` | Max reconnection attempts | 3 |
| `POSTGRESQL_RECONNECT_WAIT_TIME` | `postgresql-reconnect-wait-time` | Wait time between reconnection attempts (ms) | 3000 |

#### User Account Configuration

| Variable | Property Name | Description |
|----------|---------------|-------------|
| `POSTGRESQL_USER_REQUIRED` | `postgresql-user-required` | Require database user account for authentication | false |
| `POSTGRESQL_USER_PASSWORD_HISTORY` | `postgresql-user-password-history` | Number of previous passwords to remember | 24 |

#### Session Recording

| Variable | Property Name | Description |
|----------|---------------|-------------|
| `RECORDING_SEARCH_PATH` | `recording-search-path` | Path to search for session recordings |
| `RECORDING_STORAGE_PATH` | `recording-storage-path` | Path to store session recordings |

---

## Custom Configuration File (Advanced)

If you need configuration options not available via environment variables, you can create a custom `guacamole.properties` file:

1. **Create a volume mount:**
   ```yaml
   volumes:
     - ./guacamole.properties:/home/guacamole/.guacamole/guacamole.properties:ro
   ```

2. **Create the properties file:**
   ```bash
   # /path/to/guacamole.properties
   guacd-hostname: guacd
   guacd-port: 4822
   postgresql-hostname: guacamole-db
   # ... additional properties
   ```

**Note:** When `ENABLE_ENVIRONMENT_PROPERTIES` is enabled, environment variables take precedence over properties files.

---

## Configuration Best Practices

### For Production Use

1. **Change default passwords:**
   ```yaml
   POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # Use .env file with strong password
   ```

2. **Set appropriate session timeouts:**
   ```yaml
   API_SESSION_TIMEOUT: 480  # 8 hours for business hours
   ```

3. **Limit languages (if needed):**
   ```yaml
   ALLOWED_LANGUAGES: en  # Only if you only need English
   ```

4. **Use external secret management:**
   - Store passwords in `.env` file (not in git)
   - Use Docker secrets or Kubernetes secrets for production
   - Consider using a secrets manager (Vault, AWS Secrets Manager, etc.)

### For Development/Testing

1. **Increase logging for debugging:**
   ```yaml
   guacd:
     command: ["-b", "0.0.0.0", "-l", "4822", "-L", "debug"]
   ```

2. **Shorter session timeouts:**
   ```yaml
   API_SESSION_TIMEOUT: 60  # 1 hour for testing
   ```

---

## Environment Variable Reference

### Complete List of Available Variables

Based on the [official documentation](https://guacamole.apache.org/doc/gug/configuring-guacamole.html), here are commonly used environment variables:

#### Core Configuration
- `GUACD_HOSTNAME`
- `GUACD_PORT`
- `GUACD_SSL` (requires certificate and key)
- `ENABLE_ENVIRONMENT_PROPERTIES`

#### Session/API
- `API_SESSION_TIMEOUT`
- `API_MAX_REQUEST_SIZE`
- `ALLOWED_LANGUAGES

#### PostgreSQL
- `POSTGRESQL_HOSTNAME`
- `POSTGRESQL_DATABASE`
- `POSTGRESQL_USER`
- `POSTGRESQL_PASSWORD`
- `POSTGRESQL_PORT`
- `POSTGRESQL_AUTO_CREATE_ACCOUNTS`
- `POSTGRESQL_USER_REQUIRED`
- `POSTGRESQL_MAX_CONNECTIONS`
- `POSTGRESQL_MAX_IDLE_CONNECTIONS`
- `POSTGRESQL_MAX_RECONNECT_ATTEMPTS`
- `POSTGRESQL_RECONNECT_WAIT_TIME`

#### Security
- `TRUSTED_PROXIES`
- `DENIED_PROXIES`

#### Recording
- `RECORDING_SEARCH_PATH`
- `RECORDING_STORAGE_PATH`

---

## Verifying Configuration

### Check Environment Variables

```bash
# View environment variables in running container
docker exec guacamole env | grep -E "GUAC|POSTGRES|API_"
```

### Check guacd Configuration

```bash
# View guacd process and arguments
docker exec guacd ps aux | grep guacd
```

### View Logs

```bash
# Guacamole web application logs
docker logs guacamole

# guacd daemon logs
docker logs guacd
```

### Test Configuration

1. **Access web interface:** `http://[server-ip]:8080/guacamole/`
2. **Log in:** Use default credentials or configured users
3. **Create a test connection:** Add an RDP/VNC connection
4. **Connect:** Verify the connection works

---

## Troubleshooting Configuration

### Common Issues

**1. Cannot connect to guacd:**
```
ERROR: Connection refused
```
- Check `GUACD_HOSTNAME` and `GUACD_PORT`
- Verify guacd is running: `docker logs guacd`
- Ensure containers are on the same Docker network

**2. Database connection fails:**
```
ERROR: Connection to database failed
```
- Verify `POSTGRESQL_*` variables
- Check database container is healthy: `docker ps`
- Test database connection: `docker exec guacamole-postgres psql -U guacamole_user -d guacamole_db`

**3. Session expires too quickly:**
- Increase `API_SESSION_TIMEOUT` value
- Set to `0` for unlimited (not recommended for security)

**4. Large file uploads fail:**
- Increase `API_MAX_REQUEST_SIZE`
- Also check reverse proxy limits (nginx, etc.)

---

## References

- **Official Configuration Documentation:** https://guacamole.apache.org/doc/gug/configuring-guacamole.html
- **Docker Installation Guide:** https://guacamole.apache.org/doc/gug/installing-guacamole.html
- **Database Setup:** https://guacamole.apache.org/doc/gug/postgresql-auth.html
- **Connection Options:** See `guacoption.pdf` in project root

---

*Last Updated: Based on Guacamole 1.5.4 and official documentation*

