const EXEMPT_PATHS = new Set(['/select-branch', '/signin']);

export default function ({ store, route, redirect }) {
  if (!store.state.auth || !store.state.auth.loggedIn) return;
  if (EXEMPT_PATHS.has(route.path)) return;
  if (!store.getters.needsBranchSelection) return;

  const redirectTo = route.fullPath && route.fullPath !== '/'
    ? route.fullPath
    : '/account';
  return redirect(`/select-branch?redirect=${encodeURIComponent(redirectTo)}`);
}
