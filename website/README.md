# Renew Vault Website

Static marketing and legal site for **Renew Vault**, deployed via [GitHub Pages](https://pages.github.com/) from the `/website` folder in this repository.

**Live URL (after deployment):** `https://<username>.github.io/<repo-name>/`

Example for this repo: `https://<your-github-username>.github.io/renew_vault/`

---

## Folder structure

```
website/
├── .nojekyll              # Disables Jekyll processing (required for pure HTML)
├── index.html             # Homepage
├── privacy-policy.html    # Privacy Policy
├── terms.html             # Terms of Service
├── support.html           # Support & FAQ
├── contact.html           # Contact form (mailto:)
├── robots.txt             # Crawler rules + sitemap reference
├── sitemap.xml            # All public pages for search engines
├── assets/
│   └── favicon.svg        # Site favicon
├── css/
│   └── styles.css         # Shared stylesheet
├── images/
│   ├── renew_vault_logo.svg
│   └── og-image.svg       # Open Graph / Twitter Card preview
├── README.md              # This file
└── js/
    └── main.js            # Nav, FAQ accordion, scroll reveal, contact form
```

All asset and page links are **relative** (e.g. `css/styles.css`, `privacy-policy.html`) so the site works on GitHub Pages project URLs without configuration changes.

---

## Deploy to GitHub Pages

### Prerequisites

1. The `website/` folder is committed and pushed to GitHub on the branch you want to publish (typically `main`).
2. You have admin access to the repository on GitHub.

### Step-by-step

#### 1. Push the website to GitHub

From your local machine, ensure the latest `website/` files are on the remote:

```bash
git add website/
git commit -m "Add or update Renew Vault website"
git push origin main
```

Skip this if the files are already on the remote.

#### 2. Open GitHub Pages settings

1. Go to your repository on GitHub.
2. Click **Settings** → **Pages** (under “Code and automation”).

#### 3. Configure the source

Under **Build and deployment**:

| Setting | Value |
|---------|--------|
| **Source** | Deploy from a branch |
| **Branch** | `main` (or your default branch) |
| **Folder** | `/website` |

Click **Save**.

#### 4. Wait for deployment

GitHub builds and publishes the site (usually 1–3 minutes). Refresh the **Pages** settings page until you see:

> Your site is live at `https://<username>.github.io/<repo-name>/`

#### 5. Verify the live site

Open the URL and check:

- [ ] Homepage loads with styles and logo
- [ ] Favicon appears in the browser tab
- [ ] Navigation links work (Privacy, Terms, Support, Contact)
- [ ] Footer links include Privacy Policy, Terms, Support, and Contact
- [ ] `robots.txt` and `sitemap.xml` load at the site root
- [ ] Replace `jayanthrajiv1983` in HTML, `robots.txt`, and `sitemap.xml` with your GitHub username
- [ ] Mobile menu toggles correctly
- [ ] Contact form opens your email client (no server-side submission)

#### 6. Optional — custom domain

To use a domain like `renewvault.app`:

1. Add a `CNAME` file in `website/` containing your domain (one line, no `https://`).
2. Configure DNS at your registrar (A/CNAME records per [GitHub docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)).
3. Enable **Enforce HTTPS** in Pages settings after DNS propagates.

---

## Updating content

### Marketing pages (homepage, support, contact)

Edit the HTML files directly in `website/`:

- `index.html` — hero, features, FAQ, CTAs
- `support.html` — troubleshooting and FAQ
- `contact.html` — contact channels and mailto form

Shared chrome (header nav and footer) is marked with HTML comments in each file — keep those blocks identical across all five pages.

Styles: `css/styles.css`  
Behavior: `js/main.js`

### Legal pages (privacy, terms)

Source-of-truth markdown lives in the repo root `docs/` folder:

| Website file | Source markdown |
|--------------|-----------------|
| `privacy-policy.html` | `docs/privacy-policy.md` |
| `terms.html` | `docs/terms-of-service.md` |
| `support.html` (partial) | `docs/support.md` |

**Workflow when legal text changes:**

1. Edit the `.md` file in `docs/`.
2. Copy the updated sections into the matching `website/*.html` file (HTML uses semantic headings, tables, and the legal layout with table-of-contents sidebar).
3. Update the **Last Updated** `<time datetime="YYYY-MM">` in the page header if the policy changed materially.
4. Commit, push, and wait for GitHub Pages to redeploy (automatic on push to the published branch).

### Google Play link

When the app is listed on Google Play, replace the placeholder `href="#"` on `.btn-play` buttons in `index.html` with the full Play Store URL:

```html
<a href="https://play.google.com/store/apps/details?id=com.renewvault.app" class="btn btn-primary btn-play" data-package="com.renewvault.app" ...>
```

**Package ID:** `com.renewvault.app` (also set on `data-package` and in page meta on legal pages).

That is the only intentional external product link on the site.

---

## SEO, Open Graph, and sitemap

Before deploying (or after your GitHub Pages URL is known), replace the placeholder base URL **`jayanthrajiv1983`** everywhere it appears:

| File | What to update |
|------|----------------|
| All `*.html` | `<link rel="canonical">`, `og:url`, `og:image`, `twitter:image` |
| `robots.txt` | `Sitemap:` line |
| `sitemap.xml` | Every `<loc>` entry |

**Placeholder base URL:** `https://jayanthrajiv1983.github.io/renew_vault/`

Example after replace: `https://johndoe.github.io/renew_vault/`

Quick find-and-replace in the `website/` folder:

```
Find:    jayanthrajiv1983
Replace: your-github-username
```

### Files added for Google Play / search

| File | Purpose |
|------|---------|
| `robots.txt` | Allows all crawlers; points to sitemap |
| `sitemap.xml` | Lists all 5 public pages for search engines |
| `images/og-image.svg` | Social preview image (Open Graph / Twitter Card) |

Each HTML page includes:

- `<meta name="description">` and optional `keywords`
- `<link rel="canonical">` (absolute URL — update placeholder before deploy)
- Open Graph tags (`og:title`, `og:description`, `og:url`, `og:type`, `og:image`, `og:site_name`)
- Twitter Card tags (`twitter:card`, `twitter:title`, `twitter:description`, `twitter:image`)
- `<link rel="icon">` → `assets/favicon.svg` on every page
- `<link rel="apple-touch-icon">` → `images/renew_vault_logo.svg`

**Note:** Some social platforms prefer PNG/JPG for `og:image` (1200×630). The included SVG works for many previews; export `images/og-image.svg` to PNG if a platform rejects SVG.

### Google Play Console URLs

When submitting to Google Play, use these live URLs (after deploy + placeholder replace):

| Field | URL |
|-------|-----|
| Privacy Policy | `https://<username>.github.io/renew_vault/privacy-policy.html` |
| Terms (if required) | `https://<username>.github.io/renew_vault/terms.html` |
| Website | `https://<username>.github.io/renew_vault/` |
| Support / Contact | `https://<username>.github.io/renew_vault/support.html` or `contact.html` |

### Favicon and logo

- Favicon: `assets/favicon.svg` — linked from every page via `<link rel="icon" href="assets/favicon.svg" type="image/svg+xml">`
- Logo: `images/renew_vault_logo.svg` — used in the header and contact page

After replacing SVGs, hard-refresh the browser (cache) to confirm updates.

---

## Local preview

No build step required. Serve the folder with any static file server:

```bash
# Python 3
cd website
python -m http.server 8080
```

Open `http://localhost:8080/index.html`.

Or open `index.html` directly in a browser for a quick check (some features behave best over HTTP).

---

## Technical notes

- **`.nojekyll`** — Prevents GitHub from running Jekyll, which would ignore paths like `assets/` and break static delivery.
- **No backend** — The contact form builds a `mailto:` link in JavaScript; nothing is posted to a server.
- **Relative URLs only** — Except `mailto:` links and the future Google Play Store URL.
- **App code** — Flutter/Dart source in `lib/` is separate; this site does not import or build the mobile app.

---

## Troubleshooting deployment

| Problem | Likely cause | Fix |
|---------|--------------|-----|
| 404 on homepage | Wrong folder selected | Set Pages folder to `/website`, not `/ (root)` |
| Unstyled pages | Jekyll ignoring assets | Ensure `website/.nojekyll` exists and is committed |
| Broken nav on live site only | Absolute paths | Use relative paths (`css/styles.css`, not `/css/styles.css`) |
| Favicon missing | Wrong path or cache | Confirm `assets/favicon.svg` exists; hard-refresh |
| Old content after push | CDN cache | Wait a few minutes; try incognito window |

For GitHub Pages status, check the **Actions** or **Pages** tab in repository settings.
