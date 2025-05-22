import {
  onDocumentUpdated,
  FirestoreEvent,
  Change,
  DocumentSnapshot,
} from "firebase-functions/v2/firestore";
import {onRequest, HttpsOptions} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const firestore = admin.firestore();

/**
 * Cloud Function (v2) que se activa cuando se actualiza un documento
 * en la colección 'usuarios'.
 * Actualiza el 'usuarioNombre' en todos los comentarios hechos por ese usuario.
 */
export const updateUserCommentNamesOnProfileChange = onDocumentUpdated(
  "usuarios/{userId}",
  async (
    event: FirestoreEvent<
      Change<DocumentSnapshot> | undefined,
      {userId: string}
    >,
  ) => {
    if (!event.data) {
      logger.log("Event data is undefined, skipping.");
      return null;
    }

    const change = event.data;
    const newValue = change.after.data();
    const previousValue = change.before.data();
    const userId = event.params.userId;

    if (!newValue || !previousValue) {
      logger.log(
        "User data (new or previous) missing for user:",
        userId,
      );
      return null;
    }

    const newName = newValue.nombre;
    const oldName = previousValue.nombre;

    // Si el nombre no ha cambiado, no hacer nada.
    if (newName === oldName) {
      logger.log(
        `Name for user ${userId} has not changed. No update.`,
      );
      return null;
    }

    logger.log(
      `User ${userId} name changed from "${oldName}" ` +
      `to "${newName}". Updating comments.`,
    );

    const commentsSnapshot = await firestore
      .collectionGroup("comentarios")
      .where("usuarioId", "==", userId)
      .get();

    if (commentsSnapshot.empty) {
      logger.log(`No comments found for user ${userId}.`);
      return null;
    }

    const batch = firestore.batch();
    let opsCount = 0;

    commentsSnapshot.forEach((doc) => {
      if (doc.data().usuarioNombre !== newName) {
        batch.update(doc.ref, {usuarioNombre: newName});
        opsCount++;
        if (opsCount >= 490) {
          logger.warn(
            "Approaching batch limit. " +
            "Consider multiple commits for active users.",
          );
        }
      }
    });

    if (opsCount > 0) {
      try {
        await batch.commit();
        logger.log(
          `Updated names in ${opsCount} comments for user ${userId}.`,
        );
      } catch (error) {
        logger.error(
          `Error committing batch for user ${userId}:`,
          error,
        );
      }
    } else {
      logger.log(
        `No comments needed updating for user ${userId}.`,
      );
    }
    return null;
  },
);

const httpsOptions: HttpsOptions = {timeoutSeconds: 540, memory: "1GiB"};

export const migrateAllCommentUserNames = onRequest(
  httpsOptions,
  async (req, res) => {
    const configRef = firestore
      .collection("configuraciones")
      .doc("actualizacion_nombres_cf_status");
    const configDoc = await configRef.get();
    const data = configDoc.data();

    if (
      configDoc.exists &&
      data?.migracionCompletada === true &&
      req.query.force !== "true"
    ) {
      logger.info(
        "La migración global de nombres ya fue completada.",
      );
      res
        .status(200)
        .send(
          "Migración global completada. " +
          "Añade ?force=true para re-ejecutar.",
        );
      return;
    }

    logger.info(
      "Iniciando migración global de nombres en comentarios...",
    );
    let totalProcessed = 0;
    let totalUpdated = 0;

    try {
      const recetas = await firestore.collection("recetas").get();
      let batch = firestore.batch();
      let batchCount = 0;

      for (const receta of recetas.docs) {
        const comentarios = await receta.ref
          .collection("comentarios")
          .get();
        for (const comentario of comentarios.docs) {
          totalProcessed++;
          const cData = comentario.data();
          if (cData?.usuarioId) {
            const userSnap = await firestore
              .collection("usuarios")
              .doc(cData.usuarioId)
              .get();
            const uData = userSnap.data();
            let correctName = "Usuario desconocido";

            if (userSnap.exists && uData?.nombre) {
              correctName = uData.nombre;
            } else if (!userSnap.exists) {
              correctName = "Usuario eliminado";
            }

            if (cData.usuarioNombre !== correctName) {
              batch.update(comentario.ref, {
                usuarioNombre: correctName,
              });
              batchCount++;
              totalUpdated++;
            }

            if (batchCount >= 490) {
              await batch.commit();
              logger.log(
                `Commit durante migración: ${batchCount} ops.`,
              );
              batch = firestore.batch();
              batchCount = 0;
            }
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        logger.log(
          `Commit final: ${batchCount} ops durante migración.`,
        );
      }

      await configRef.set({
        migracionCompletada: true,
        ultimaEjecucion: admin.firestore.FieldValue.serverTimestamp(),
        comentariosProcesados: totalProcessed,
        comentariosActualizados: totalUpdated,
      });

      const msg =
        `Migración completada. Procesados: ${totalProcessed}, ` +
        `Actualizados: ${totalUpdated}.`;
      logger.info(msg);
      res.status(200).send(msg);
    } catch (error) {
      logger.error(
        "Error en migración global de nombres:",
        error,
      );
      res
        .status(500)
        .send(
          "Error durante la migración. Revisa los logs.",
        );
    }
  },
);
