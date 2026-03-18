# MaxLab Navigator Theme

`maxlab_navigator_theme` is a Python package that installs three JupyterLab prebuilt extensions for MaxLab:

- `@navigatorbbs/maxlab-navigator-light`
- `@navigatorbbs/maxlab-navigator-dark`
- `@navigatorbbs/maxlab-branding`

The light and dark themes keep native JupyterLab behavior while applying a NavigatorBBS-inspired palette and subtle accent styling. The branding extension adds the MaxLab logo above the file browser launcher controls in the left sidebar.

## Development

Build each frontend extension from this directory:

```powershell
npm install --prefix .\js\maxlab-navigator-light
npm install --prefix .\js\maxlab-navigator-dark
npm install --prefix .\js\maxlab-branding

npm run build:prod --prefix .\js\maxlab-navigator-light
npm run build:prod --prefix .\js\maxlab-navigator-dark
npm run build:prod --prefix .\js\maxlab-branding
```

Then build the Python package:

```powershell
python -m build .\packages\maxlab_navigator_theme
```
