// Add Jest matchers for toThrowError and other missing methods

// Retry flaky tests up to 2 times to improve CI stability
jest.retryTimes(2, { logErrorsBeforeRetry: true });

export {};

declare global {
  namespace jest {
    interface Matchers<R> {
      toThrowError(error?: string | RegExp | Error): R;
      toBeCalledTimes(expected: number): R;
    }
  }
}
