const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

exports.cleanupFavoritesOnRestaurantDelete = onDocumentDeleted(
  {
    document: "restaurants/{restaurantId}",
    region: "asia-south1",
  },
  async (event) => {
    const restaurantId = event.params.restaurantId;
    if (!restaurantId) {
      return;
    }

    let lastUserDoc = null;

    while (true) {
      let usersQuery = db
        .collection("users")
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(200);

      if (lastUserDoc) {
        usersQuery = usersQuery.startAfter(lastUserDoc);
      }

      const usersSnapshot = await usersQuery.get();
      if (usersSnapshot.empty) {
        break;
      }

      const batch = db.batch();
      let hasWrites = false;

      for (const userDoc of usersSnapshot.docs) {
        const favoritesCollection = userDoc.ref.collection("favorites");
        const restaurantsFavRef = favoritesCollection.doc("restaurants");
        const itemsFavRef = favoritesCollection.doc("items");

        const [restaurantsFavSnap, itemsFavSnap] = await Promise.all([
          restaurantsFavRef.get(),
          itemsFavRef.get(),
        ]);

        if (restaurantsFavSnap.exists) {
          const restaurantsData = restaurantsFavSnap.data() || {};
          if (Object.prototype.hasOwnProperty.call(restaurantsData, restaurantId)) {
            batch.update(restaurantsFavRef, {
              [restaurantId]: admin.firestore.FieldValue.delete(),
            });
            hasWrites = true;
          }
        }

        if (itemsFavSnap.exists) {
          const itemsData = itemsFavSnap.data() || {};
          const itemDeletes = {};

          for (const [itemId, value] of Object.entries(itemsData)) {
            if (
              value &&
              typeof value === "object" &&
              value.restaurantId === restaurantId
            ) {
              itemDeletes[itemId] = admin.firestore.FieldValue.delete();
            }
          }

          if (Object.keys(itemDeletes).length > 0) {
            batch.update(itemsFavRef, itemDeletes);
            hasWrites = true;
          }
        }
      }

      if (hasWrites) {
        await batch.commit();
      }

      lastUserDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];
      if (usersSnapshot.size < 200) {
        break;
      }
    }
  }
);
