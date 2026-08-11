/**
 * 测试专用的业务生命周期故障注入开关。默认关闭，不改变正常应用行为。
 */
export class LifecycleFaultInjection {
  private static staleCallbackCrashEnabled: boolean = false;
  private static staleCallbackScheduled: boolean = false;
  private static staleCallbackCleared: boolean = false;

  static enableStaleCallbackCrash(): void {
    LifecycleFaultInjection.staleCallbackCrashEnabled = true;
    LifecycleFaultInjection.staleCallbackScheduled = false;
    LifecycleFaultInjection.staleCallbackCleared = false;
  }

  static shouldCrashFromStaleCallback(): boolean {
    return LifecycleFaultInjection.staleCallbackCrashEnabled;
  }

  static recordStaleCallbackScheduled(): void {
    LifecycleFaultInjection.staleCallbackScheduled = true;
  }

  static recordStaleCallbackCleared(): void {
    LifecycleFaultInjection.staleCallbackCleared = true;
  }

  static wasStaleCallbackScheduled(): boolean {
    return LifecycleFaultInjection.staleCallbackScheduled;
  }

  static wasStaleCallbackCleared(): boolean {
    return LifecycleFaultInjection.staleCallbackCleared;
  }

  static disableStaleCallbackCrash(): void {
    LifecycleFaultInjection.staleCallbackCrashEnabled = false;
    LifecycleFaultInjection.staleCallbackScheduled = false;
    LifecycleFaultInjection.staleCallbackCleared = false;
  }
}
