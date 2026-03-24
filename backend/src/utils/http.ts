export function getParam(value: string | string[] | undefined, label: string): string {
  if (typeof value === 'string' && value.length > 0) {
    return value;
  }

  throw new Error(`${label} is required.`);
}
