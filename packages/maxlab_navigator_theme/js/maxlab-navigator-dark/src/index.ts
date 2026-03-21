import type {
  JupyterFrontEnd,
  JupyterFrontEndPlugin
} from '@jupyterlab/application';
import { IThemeManager } from '@jupyterlab/apputils';
import { ITranslator } from '@jupyterlab/translation';

const plugin: JupyterFrontEndPlugin<void> = {
  id: '@navigatorbbs/maxlab-navigator-dark:plugin',
  description: 'Adds the MaxLab Navigator dark theme.',
  requires: [IThemeManager, ITranslator],
  autoStart: true,
  activate: (
    app: JupyterFrontEnd,
    manager: IThemeManager,
    translator: ITranslator
  ) => {
    const trans = translator.load('jupyterlab');
    const style = '@navigatorbbs/maxlab-navigator-dark/index.css';

    manager.register({
      name: 'MaxLab Navigator Dark',
      displayName: trans.__('MaxLab Navigator Dark'),
      isLight: false,
      themeScrollbars: true,
      load: () => manager.loadCSS(style),
      unload: () => Promise.resolve(undefined)
    });
  }
};

export default plugin;
