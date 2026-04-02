# Canvas LMS — Self-Hosted (Full Admin Access)

A complete self-hosted deployment of [Canvas LMS](https://github.com/instructure/canvas-lms) using Docker Compose, with full administrative access, configuration templates, and operational scripts.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- - [Quick Start](#quick-start)
  - - [Repository Structure](#repository-structure)
    - - [Configuration](#configuration)
      - - [Admin Access](#admin-access)
        - - [Useful Scripts](#useful-scripts)
          - - [Backup & Restore](#backup--restore)
            - - [Upgrading](#upgrading)
              - - [Troubleshooting](#troubleshooting)
               
                - ---

                ## Prerequisites

                - Docker >= 24.x
                - - Docker Compose >= 2.x
                  - - A Linux server (Ubuntu 22.04 LTS recommended) with at least:
                    -   - 4 CPU cores
                        -   - 8 GB RAM
                            -   - 40 GB disk space
                                - - A registered domain name with DNS pointing to your server
                                  - - SMTP credentials for outgoing email
                                   
                                    - ---

                                    ## Quick Start

                                    ```bash
                                    # 1. Clone this repository
                                    git clone https://github.com/YOUR_USERNAME/canvas-lms-selfhosted.git
                                    cd canvas-lms-selfhosted

                                    # 2. Copy and configure environment variables
                                    cp .env.example .env
                                    nano .env   # Fill in all required values

                                    # 3. Copy Canvas config templates
                                    cp config/database.yml.example config/database.yml
                                    cp config/cache_store.yml.example config/cache_store.yml
                                    cp config/outgoing_mail.yml.example config/outgoing_mail.yml
                                    cp config/security.yml.example config/security.yml
                                    cp config/dynamic_settings.yml.example config/dynamic_settings.yml

                                    # 4. Run the setup script (initialises DB, assets, and creates admin user)
                                    chmod +x scripts/setup.sh
                                    ./scripts/setup.sh

                                    # 5. Start all services
                                    docker compose up -d

                                    # 6. Visit https://YOUR_DOMAIN and log in with the admin credentials you set in .env
                                    ```

                                    ---

                                    ## Repository Structure

                                    ```
                                    canvas-lms-selfhosted/
                                    ├── docker-compose.yml          # All services: Canvas, Postgres, Redis, Nginx
                                    ├── .env.example                # All required environment variables
                                    ├── config/
                                    │   ├── database.yml.example
                                    │   ├── cache_store.yml.example
                                    │   ├── outgoing_mail.yml.example
                                    │   ├── security.yml.example
                                    │   ├── dynamic_settings.yml.example
                                    │   └── nginx/
                                    │       └── canvas.conf         # Nginx reverse-proxy config
                                    ├── scripts/
                                    │   ├── setup.sh                # First-time initialisation
                                    │   ├── admin-console.sh        # Open Rails console as admin
                                    │   ├── create-admin.sh         # Create / reset admin user
                                    │   ├── backup.sh               # Database + uploads backup
                                    │   └── restore.sh              # Restore from backup
                                    └── README.md
                                    ```

                                    ---

                                    ## Configuration

                                    All configuration is driven by the `.env` file and the YAML files under `config/`.

                                    | File | Purpose |
                                    |------|---------|
                                    | `.env` | Master environment variables (DB passwords, domain, SMTP, secrets) |
                                    | `config/database.yml` | PostgreSQL connection settings |
                                    | `config/cache_store.yml` | Redis cache configuration |
                                    | `config/outgoing_mail.yml` | SMTP / sendmail settings |
                                    | `config/security.yml` | Encryption key for cookies & sessions |
                                    | `config/dynamic_settings.yml` | Feature flags and service endpoints |
                                    | `config/nginx/canvas.conf` | Nginx reverse proxy with SSL termination |

                                    ---

                                    ## Admin Access

                                    ### First-Time Admin Account

                                    The `scripts/setup.sh` script automatically creates an admin account using the credentials defined in your `.env` file:

                                    ```
                                    CANVAS_ADMIN_EMAIL=admin@yourdomain.com
                                    CANVAS_ADMIN_PASSWORD=ChangeMe123!
                                    CANVAS_ADMIN_NAME=Administrator
                                    ```

                                    ### Accessing the Rails Admin Console

                                    ```bash
                                    ./scripts/admin-console.sh
                                    ```

                                    This opens an interactive Ruby on Rails console inside the Canvas container with full database access.

                                    ### Creating or Resetting an Admin User

                                    ```bash
                                    ./scripts/create-admin.sh admin@yourdomain.com "New Password123!"
                                    ```

                                    ### Site Admin Panel

                                    Log in and navigate to:
                                    ```
                                    https://YOUR_DOMAIN/accounts/site_admin
                                    ```

                                    From here you can manage all root-level accounts, authentication providers, plugins, and feature flags.

                                    ### Granting Admin to an Existing User (via console)

                                    ```ruby
                                    user = User.find_by(email: 'user@example.com')
                                    Account.site_admin.account_users.create!(user: user, role: Role.get_built_in_role('AccountAdmin'))
                                    ```

                                    ---

                                    ## Useful Scripts

                                    | Script | Description |
                                    |--------|-------------|
                                    | `scripts/setup.sh` | Full first-time setup: DB init, asset compile, admin user creation |
                                    | `scripts/admin-console.sh` | Interactive Rails console inside the Canvas container |
                                    | `scripts/create-admin.sh` | Create or reset an admin user by email |
                                    | `scripts/backup.sh` | Dump PostgreSQL + tar uploads to `./backups/` |
                                    | `scripts/restore.sh` | Restore a backup created by `backup.sh` |

                                    ---

                                    ## Backup & Restore

                                    ### Create a backup

                                    ```bash
                                    ./scripts/backup.sh
                                    # Creates: ./backups/canvas_backup_YYYYMMDD_HHMMSS.tar.gz
                                    ```

                                    ### Restore a backup

                                    ```bash
                                    ./scripts/restore.sh ./backups/canvas_backup_20240101_120000.tar.gz
                                    ```

                                    ---

                                    ## Upgrading

                                    ```bash
                                    # Pull the latest Canvas image
                                    docker compose pull canvas

                                    # Run migrations
                                    docker compose run --rm canvas bundle exec rake db:migrate RAILS_ENV=production

                                    # Recompile assets
                                    docker compose run --rm canvas bundle exec rake canvas:compile_assets RAILS_ENV=production

                                    # Restart services
                                    docker compose up -d
                                    ```

                                    ---

                                    ## Troubleshooting

                                    | Symptom | Fix |
                                    |---------|-----|
                                    | Canvas shows 500 error | Check logs: `docker compose logs canvas` |
                                    | Email not sending | Verify SMTP settings in `config/outgoing_mail.yml` and `.env` |
                                    | Slow page loads | Increase Redis/Postgres resources or enable job workers |
                                    | Asset 404s | Re-run `rake canvas:compile_assets` |
                                    | Cannot log in | Use `scripts/create-admin.sh` to reset the admin password |

                                    ---

                                    ## License

                                    MIT — see [LICENSE](LICENSE) for details.

                                    Canvas LMS is copyright Instructure, Inc. and licensed under the AGPL-3.0.
