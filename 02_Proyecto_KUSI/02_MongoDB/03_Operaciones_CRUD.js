// ================================================================
// KUSI MINIMARKET — CRUD sobre promociones
// ================================================================
use KUSI_MINIMARKET_NOSQL;

// CREATE: nueva promoción de snacks para fin de semana.
// Limpiamos solo el documento de prueba para que el bloque sea repetible.
db.promociones.deleteOne({id_promocion:'PROM-018'});
db.promociones.insertOne({
  id_promocion:'PROM-018',
  nombre:'Finde de Snacks',
  descripcion:'15% de descuento en snacks los sábados y domingos',
  categorias:['Snacks y Golosinas'],
  tipo:'descuento_porcentual',
  valor:15,
  dias_activos:[1,7], // 1=domingo ... 7=sábado
  sucursales:[1,2,3,4,5,6,7],
  fecha_inicio:'2025-09-01',
  fecha_fin:'2025-12-31',
  activa:true
});

// READ: promociones activas para una sucursal.
db.promociones.find({sucursales:1,activa:true});

// READ: promociones activas de un día concreto.
db.promociones.find({dias_activos:2,activa:true},{_id:0,nombre:1,valor:1,categorias:1});

// UPDATE: ajuste de una promoción existente.
db.promociones.updateOne(
  {id_promocion:'PROM-001'},
  {$set:{valor:12,descripcion:'12% de descuento en lacteos los martes'}}
);

// UPDATE masivo: desactivar promociones vencidas en el escenario.
db.promociones.updateMany(
  {fecha_fin:{$lt:'2025-09-16'}},
  {$set:{activa:false}}
);

// DELETE: se elimina el documento de prueba. En producción se preferiría
// desactivarlo para conservar historial.
db.promociones.deleteOne({id_promocion:'PROM-018'});

print('Total:',db.promociones.countDocuments());
print('Activas:',db.promociones.countDocuments({activa:true}));
