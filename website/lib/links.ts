export const APP_STORE_BASE_URL =
  "https://apps.apple.com/app/lock-screen-studio/id6761021115";

export function appStoreUrl(source: string): string {
  return `${APP_STORE_BASE_URL}?utm_source=website&utm_medium=${source}`;
}
