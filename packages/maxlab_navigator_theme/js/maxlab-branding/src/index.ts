import type {
  JupyterFrontEnd,
  JupyterFrontEndPlugin
} from '@jupyterlab/application';
import { IDefaultFileBrowser } from '@jupyterlab/filebrowser';
import '../style/index.css';

const BRANDING_CLASS = 'jp-MaxLabBranding';

const ensureBranding = (browser: IDefaultFileBrowser): void => {
  const toolbar = browser.node.querySelector('.jp-FileBrowser-toolbar');

  if (!(toolbar instanceof HTMLElement)) {
    return;
  }

  if (browser.node.querySelector(`.${BRANDING_CLASS}`)) {
    return;
  }

  const container = document.createElement('div');
  const logo = document.createElement('div');

  container.className = BRANDING_CLASS;
  container.setAttribute('role', 'img');
  container.setAttribute('aria-label', 'MaxLab');

  logo.className = `${BRANDING_CLASS}-logo`;
  container.appendChild(logo);

  toolbar.parentElement?.insertBefore(container, toolbar);
};

const plugin: JupyterFrontEndPlugin<void> = {
  id: '@navigatorbbs/maxlab-branding:plugin',
  description: 'Adds MaxLab branding above the file browser launcher controls.',
  requires: [IDefaultFileBrowser],
  autoStart: true,
  activate: (
    app: JupyterFrontEnd,
    defaultFileBrowser: IDefaultFileBrowser
  ) => {
    void app.restored.then(() => {
      ensureBranding(defaultFileBrowser);

      const observer = new MutationObserver(() => {
        ensureBranding(defaultFileBrowser);
      });

      observer.observe(defaultFileBrowser.node, {
        childList: true,
        subtree: true
      });
    });
  }
};

export default plugin;
