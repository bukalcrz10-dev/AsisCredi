const admin = require("firebase-admin");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");

admin.initializeApp();

const firestore = admin.firestore();

function responderCors(request, response) {
  const origin = request.headers.origin || "*";
  response.set("Access-Control-Allow-Origin", origin);
  response.set("Vary", "Origin");
  response.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  response.set("Access-Control-Allow-Methods", "POST, OPTIONS");
}

async function obtenerAuthDesdeBearer(request) {
  const cabecera = request.headers.authorization || "";
  if (!cabecera.startsWith("Bearer ")) {
    throw new Error("missing-bearer-token");
  }

  const token = cabecera.substring("Bearer ".length).trim();
  if (!token) {
    throw new Error("empty-bearer-token");
  }

  const decodedToken = await admin.auth().verifyIdToken(token);
  return {
    uid: decodedToken.uid,
    token: decodedToken,
  };
}

async function validarAdministrador(auth, mensajePermiso) {
  if (!auth) {
    throw new HttpsError(
      "unauthenticated",
      "Debes iniciar sesion para ejecutar esta accion.",
    );
  }

  const documentoAdmin = await firestore.collection("usuarios").doc(auth.uid).get();
  const perfilAdmin = documentoAdmin.data();

  if (!perfilAdmin) {
    throw new HttpsError(
      "permission-denied",
      mensajePermiso,
    );
  }

  if (perfilAdmin.activo !== true || perfilAdmin.rol !== "administrador") {
    throw new HttpsError(
      "permission-denied",
      mensajePermiso,
    );
  }

  return perfilAdmin;
}

function resolverMensajeErrorAuth(error) {
  switch (error && error.code) {
    case "auth/email-already-exists":
      return new HttpsError(
        "already-exists",
        "El correo institucional ya se encuentra registrado.",
      );
    case "auth/invalid-email":
      return new HttpsError(
        "invalid-argument",
        "El correo enviado no tiene un formato valido.",
      );
    case "auth/invalid-password":
    case "auth/password-does-not-meet-requirements":
    case "auth/weak-password":
      return new HttpsError(
        "invalid-argument",
        "La contrasena no cumple los requisitos minimos.",
      );
    case "auth/operation-not-allowed":
      return new HttpsError(
        "failed-precondition",
        "El acceso con correo y contrasena no esta habilitado en Authentication.",
      );
    default:
      return null;
  }
}

function normalizarDatosTrabajador(data) {
  return {
    nombreCompleto: `${data.nombreCompleto || ""}`.trim(),
    correo: `${data.correo || ""}`.trim().toLowerCase(),
    telefono: `${data.telefono || ""}`.trim(),
    area: `${data.area || ""}`.trim(),
    cargo: `${data.cargo || ""}`.trim(),
    rol: `${data.rol || "trabajador"}`.trim().toLowerCase(),
    password: `${data.password || ""}`,
    sedeAsignadaId: `${data.sedeAsignadaId || "sede_principal"}`.trim(),
    activo: data.activo !== false,
  };
}

function normalizarDatosActualizacionTrabajador(data) {
  return {
    uid: `${data.uid || ""}`.trim(),
    nombreCompleto: `${data.nombreCompleto || ""}`.trim(),
    correo: `${data.correo || ""}`.trim().toLowerCase(),
    telefono: `${data.telefono || ""}`.trim(),
    area: `${data.area || ""}`.trim(),
    cargo: `${data.cargo || ""}`.trim(),
    rol: `${data.rol || "trabajador"}`.trim().toLowerCase(),
    sedeAsignadaId: `${data.sedeAsignadaId || "sede_principal"}`.trim(),
    activo: data.activo !== false,
  };
}

function validarDatosTrabajador(data) {
  if (
    !data.nombreCompleto ||
    !data.correo ||
    !data.telefono ||
    !data.area ||
    !data.cargo ||
    !data.password
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Faltan datos obligatorios para crear el trabajador.",
    );
  }

  if (data.password.length < 6) {
    throw new HttpsError(
        "invalid-argument",
        "La contrasena debe tener al menos 6 caracteres.",
    );
  }

  if (data.rol !== "trabajador" && data.rol !== "administrador") {
    throw new HttpsError(
        "invalid-argument",
        "El rol enviado no es valido.",
    );
  }
}

function validarDatosActualizacionTrabajador(data) {
  if (
    !data.uid ||
    !data.nombreCompleto ||
    !data.correo ||
    !data.telefono ||
    !data.area ||
    !data.cargo
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Faltan datos obligatorios para actualizar el trabajador.",
    );
  }

  if (data.rol !== "trabajador" && data.rol !== "administrador") {
    throw new HttpsError(
        "invalid-argument",
        "El rol enviado no es valido.",
    );
  }
}

async function ejecutarCreacionTrabajador(auth, data) {
  await validarAdministrador(
      auth,
      "Solo un administrador institucional puede crear trabajadores.",
  );

  const trabajador = normalizarDatosTrabajador(data);
  validarDatosTrabajador(trabajador);

  let usuarioCreado;

  try {
    usuarioCreado = await admin.auth().createUser({
      email: trabajador.correo,
      password: trabajador.password,
      displayName: trabajador.nombreCompleto,
      disabled: !trabajador.activo,
    });

    await firestore.collection("usuarios").doc(usuarioCreado.uid).set({
      nombreCompleto: trabajador.nombreCompleto,
      correo: trabajador.correo,
      telefono: trabajador.telefono,
      area: trabajador.area,
      cargo: trabajador.cargo,
      rol: trabajador.rol,
      sedeAsignadaId: trabajador.sedeAsignadaId,
      activo: trabajador.activo,
      creadoPor: auth.uid,
      creadoEn: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      uid: usuarioCreado.uid,
      mensaje: "Trabajador creado correctamente.",
    };
  } catch (error) {
    console.error("Error al crear trabajador con acceso", {
      code: error && error.code ? error.code : null,
      message: error && error.message ? error.message : `${error}`,
    });

    if (usuarioCreado && usuarioCreado.uid) {
      try {
        await admin.auth().deleteUser(usuarioCreado.uid);
      } catch (_) {
        // Si la limpieza falla, dejamos el error original.
      }
    }

    const errorManejable = resolverMensajeErrorAuth(error);
    if (errorManejable) {
      throw errorManejable;
    }

    throw new HttpsError(
        "internal",
        `No se pudo crear el trabajador con acceso. ${
          error && error.code ? `Codigo: ${error.code}. ` : ""
        }${error && error.message ? error.message : ""}`.trim(),
    );
  }
}

async function ejecutarActualizacionTrabajador(auth, data) {
  await validarAdministrador(
      auth,
      "Solo un administrador institucional puede actualizar trabajadores.",
  );

  const trabajador = normalizarDatosActualizacionTrabajador(data);
  validarDatosActualizacionTrabajador(trabajador);

  try {
    let uidObjetivo = trabajador.uid;

    try {
      await admin.auth().updateUser(uidObjetivo, {
        email: trabajador.correo,
        displayName: trabajador.nombreCompleto,
        disabled: !trabajador.activo,
      });
    } catch (errorAuth) {
      if (errorAuth && errorAuth.code === "auth/user-not-found") {
        try {
          const usuarioAuth = await admin.auth().getUserByEmail(trabajador.correo);
          uidObjetivo = usuarioAuth.uid;

          await admin.auth().updateUser(uidObjetivo, {
            email: trabajador.correo,
            displayName: trabajador.nombreCompleto,
            disabled: !trabajador.activo,
          });
        } catch (errorCorreo) {
          if (errorCorreo && errorCorreo.code === "auth/user-not-found") {
            throw new HttpsError(
                "failed-precondition",
                "El trabajador existe en Firestore, pero no tiene cuenta activa en Authentication. Debes recrear su acceso o registrar nuevamente su cuenta.",
            );
          }

          throw errorCorreo;
        }
      } else {
        throw errorAuth;
      }
    }

    const documentoAnterior = await firestore
        .collection("usuarios")
        .doc(trabajador.uid)
        .get();

    const datosActualizados = {
      ...(documentoAnterior.data() || {}),
      nombreCompleto: trabajador.nombreCompleto,
      correo: trabajador.correo,
      telefono: trabajador.telefono,
      area: trabajador.area,
      cargo: trabajador.cargo,
      rol: trabajador.rol,
      sedeAsignadaId: trabajador.sedeAsignadaId,
      activo: trabajador.activo,
      actualizadoPor: auth.uid,
      actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
    };

    await firestore.collection("usuarios").doc(uidObjetivo).set(
        datosActualizados,
        {merge: true},
    );

    if (trabajador.uid !== uidObjetivo) {
      await firestore.collection("usuarios").doc(trabajador.uid).delete();
    }

    return {
      ok: true,
      uid: uidObjetivo,
      mensaje: "Trabajador actualizado correctamente.",
    };
  } catch (error) {
    console.error("Error al actualizar trabajador", {
      code: error && error.code ? error.code : null,
      message: error && error.message ? error.message : `${error}`,
    });

    const errorManejable = resolverMensajeErrorAuth(error);
    if (errorManejable) {
      throw errorManejable;
    }

    throw new HttpsError(
        "internal",
        `No se pudo actualizar el trabajador. ${
          error && error.code ? `Codigo: ${error.code}. ` : ""
        }${error && error.message ? error.message : ""}`.trim(),
    );
  }
}

exports.crearTrabajadorConAcceso = onCall(
    {
      region: "us-central1",
      invoker: "public",
    },
    async (request) => {
      const auth = request.auth;
      const data = request.data || {};
      return ejecutarCreacionTrabajador(auth, data);
    },
);

exports.crearTrabajadorConAccesoHttp = onRequest(
    {
      region: "us-central1",
      invoker: "public",
    },
    async (request, response) => {
      responderCors(request, response);

      if (request.method === "OPTIONS") {
        response.status(204).send("");
        return;
      }

      if (request.method !== "POST") {
        response.status(405).json({
          ok: false,
          codigo: "method-not-allowed",
          mensaje: "Solo se permite el metodo POST.",
        });
        return;
      }

      try {
        const auth = await obtenerAuthDesdeBearer(request);
        const resultado = await ejecutarCreacionTrabajador(
            auth,
            request.body || {},
        );
        response.status(200).json(resultado);
      } catch (error) {
        console.error("Error HTTP al crear trabajador", {
          code: error && error.code ? error.code : null,
          message: error && error.message ? error.message : `${error}`,
        });

        const codigo = error && error.code ? error.code : "internal";
        const mensaje = error && error.message ?
          error.message :
          "No se pudo crear el trabajador con acceso.";

        const mapaEstados = {
          "unauthenticated": 401,
          "permission-denied": 403,
          "invalid-argument": 400,
          "already-exists": 409,
          "failed-precondition": 412,
          "internal": 500,
        };

        response.status(mapaEstados[codigo] || 500).json({
          ok: false,
          codigo,
          mensaje,
        });
      }
    },
);

exports.actualizarTrabajadorHttp = onRequest(
    {
      region: "us-central1",
      invoker: "public",
    },
    async (request, response) => {
      responderCors(request, response);

      if (request.method === "OPTIONS") {
        response.status(204).send("");
        return;
      }

      if (request.method !== "POST") {
        response.status(405).json({
          ok: false,
          codigo: "method-not-allowed",
          mensaje: "Solo se permite el metodo POST.",
        });
        return;
      }

      try {
        const auth = await obtenerAuthDesdeBearer(request);
        const resultado = await ejecutarActualizacionTrabajador(
            auth,
            request.body || {},
        );
        response.status(200).json(resultado);
      } catch (error) {
        console.error("Error HTTP al actualizar trabajador", {
          code: error && error.code ? error.code : null,
          message: error && error.message ? error.message : `${error}`,
        });

        const codigo = error && error.code ? error.code : "internal";
        const mensaje = error && error.message ?
          error.message :
          "No se pudo actualizar el trabajador.";

        const mapaEstados = {
          "unauthenticated": 401,
          "permission-denied": 403,
          "invalid-argument": 400,
          "already-exists": 409,
          "failed-precondition": 412,
          "internal": 500,
        };

        response.status(mapaEstados[codigo] || 500).json({
          ok: false,
          codigo,
          mensaje,
        });
      }
    },
);

exports.restablecerContrasenaTrabajador = onCall(
    {
      region: "us-central1",
      invoker: "public",
    },
    async (request) => {
      const auth = request.auth;
      const data = request.data || {};

      await validarAdministrador(
          auth,
          "Solo un administrador institucional puede restablecer contrasenas.",
      );

      const uid = `${data.uid || ""}`.trim();
      const password = `${data.password || ""}`;

      if (!uid || !password) {
        throw new HttpsError(
            "invalid-argument",
            "Debes enviar el uid y la nueva contrasena.",
        );
      }

      if (password.length < 6) {
        throw new HttpsError(
            "invalid-argument",
            "La contrasena debe tener al menos 6 caracteres.",
        );
      }

      try {
        await admin.auth().updateUser(uid, {
          password,
        });

        return {
          ok: true,
          mensaje: "Contrasena restablecida correctamente.",
        };
      } catch (_) {
        throw new HttpsError(
            "internal",
            "No se pudo restablecer la contrasena del trabajador.",
        );
      }
    },
);

exports.restablecerContrasenaTrabajadorHttp = onRequest(
    {
      region: "us-central1",
      invoker: "public",
    },
    async (request, response) => {
      responderCors(request, response);

      if (request.method === "OPTIONS") {
        response.status(204).send("");
        return;
      }

      if (request.method !== "POST") {
        response.status(405).json({
          ok: false,
          codigo: "method-not-allowed",
          mensaje: "Solo se permite el metodo POST.",
        });
        return;
      }

      try {
        const auth = await obtenerAuthDesdeBearer(request);
        const data = request.body || {};

        await validarAdministrador(
            auth,
            "Solo un administrador institucional puede restablecer contrasenas.",
        );

        const uid = `${data.uid || ""}`.trim();
        const password = `${data.password || ""}`;

        if (!uid || !password) {
          throw new HttpsError(
              "invalid-argument",
              "Debes enviar el uid y la nueva contrasena.",
          );
        }

        if (password.length < 6) {
          throw new HttpsError(
              "invalid-argument",
              "La contrasena debe tener al menos 6 caracteres.",
          );
        }

        await admin.auth().updateUser(uid, {
          password,
        });

        response.status(200).json({
          ok: true,
          mensaje: "Contrasena restablecida correctamente.",
        });
      } catch (error) {
        console.error("Error HTTP al restablecer contrasena", {
          code: error && error.code ? error.code : null,
          message: error && error.message ? error.message : `${error}`,
        });

        const codigo = error && error.code ? error.code : "internal";
        const mensaje = error && error.message ?
          error.message :
          "No se pudo restablecer la contrasena del trabajador.";

        const mapaEstados = {
          "unauthenticated": 401,
          "permission-denied": 403,
          "invalid-argument": 400,
          "failed-precondition": 412,
          "internal": 500,
        };

        response.status(mapaEstados[codigo] || 500).json({
          ok: false,
          codigo,
          mensaje,
        });
      }
    },
);
