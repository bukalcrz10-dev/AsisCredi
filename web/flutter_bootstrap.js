{{flutter_js}}
{{flutter_build_config}}

// Cambia en cada compilación: evita reutilizar el programa de una versión
// anterior cuando un navegador conserva su caché o un service worker antiguo.
const versionPanel = {{flutter_service_worker_version}};
for (const compilacion of _flutter.buildConfig.builds) {
  if (compilacion.mainJsPath) {
    const entrada = new URL(compilacion.mainJsPath, document.baseURI);
    entrada.searchParams.set('v', String(versionPanel));
    compilacion.mainJsPath = entrada.toString();
  }
}

_flutter.loader.load({
  serviceWorkerSettings: {serviceWorkerVersion: versionPanel}
});
