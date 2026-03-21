import type {
  JupyterFrontEnd,
  JupyterFrontEndPlugin
} from '@jupyterlab/application';
import { IThemeManager } from '@jupyterlab/apputils';
import { ITranslator } from '@jupyterlab/translation';

const plugin: JupyterFrontEndPlugin<void> = {
  id: '@navigatorbbs/maxlab-navigator-light:plugin',
  description: 'Adds the MaxLab Navigator light theme.',
  requires: [IThemeManager, ITranslator],
  autoStart: true,
  activate: (
    app: JupyterFrontEnd,
    manager: IThemeManager,
    translator: ITranslator
  ) => {
    const trans = translator.load('jupyterlab');
    const style = '@navigatorbbs/maxlab-navigator-light/index.css';

    manager.register({
      name: 'MaxLab Navigator Light',
      displayName: trans.__('MaxLab Navigator Light'),
      isLight: true,
      themeScrollbars: false,
      load: () => manager.loadCSS(style),
      unload: () => Promise.resolve(undefined)
    });
  }
};

export default plugin;
