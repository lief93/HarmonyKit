export class Deferred<T> {
  readonly promise: Promise<T>;
  private complete: (value: T) => void = (_value: T): void => {
  };

  constructor() {
    this.promise = new Promise<T>((resolve) => {
      this.complete = (value: T): void => resolve(value);
    });
  }

  resolve(value: T): void {
    this.complete(value);
  }
}

export function createDeferred<T>(): Deferred<T> {
  return new Deferred<T>();
}
