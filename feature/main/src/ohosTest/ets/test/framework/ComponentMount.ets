import { UIAbility } from '@kit.AbilityKit';
import { ComponentContent, OverlayManager, UIContext, window } from '@kit.ArkUI';

export class MountedComponent {
  private readonly overlayManager: OverlayManager;
  private readonly content: ComponentContent<Object>;

  constructor(overlayManager: OverlayManager, content: ComponentContent<Object>) {
    this.overlayManager = overlayManager;
    this.content = content;
  }

  unmount(): void {
    this.overlayManager.removeComponentContent(this.content);
    this.content.dispose();
  }
}

export async function mountComponent(
  ability: UIAbility,
  builder: WrappedBuilder<[]>
): Promise<MountedComponent> {
  const hostWindow: window.Window = await window.getLastWindow(ability.context);
  const uiContext: UIContext = hostWindow.getUIContext();
  const overlayManager: OverlayManager = uiContext.getOverlayManager();
  const content: ComponentContent<Object> = new ComponentContent<Object>(uiContext, builder);

  overlayManager.addComponentContent(content);
  return new MountedComponent(overlayManager, content);
}
