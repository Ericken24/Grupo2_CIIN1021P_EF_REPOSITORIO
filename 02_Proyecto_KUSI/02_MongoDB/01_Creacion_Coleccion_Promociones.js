// ================================================================
// KUSI MINIMARKET — MongoDB: promociones
// ================================================================
// MongoDB se usa aquí para documentos semiestructurados. Una promoción
// puede aplicar a categorías, productos, días o sucursales diferentes,
// por lo que el documento puede incorporar esos campos sin obligar a
// ampliar un esquema relacional cada vez que aparece una variante.

use KUSI_MINIMARKET_NOSQL;

if (!db.getCollectionNames().includes('promociones')) {
  db.createCollection('promociones', {
    validator: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['id_promocion','nombre','tipo','activa'],
        properties: {
          id_promocion: { bsonType: 'string' },
          nombre: { bsonType: 'string' },
          tipo: { bsonType: 'string' },
          activa: { bsonType: 'bool' }
        }
      }
    },
    validationLevel: 'strict',
    validationAction: 'error'
  });
}

db.promociones.createIndex({id_promocion:1},{unique:true});
db.promociones.createIndex({sucursales:1,dias_activos:1,activa:1});

print('Coleccion, validador e indices listos.');
