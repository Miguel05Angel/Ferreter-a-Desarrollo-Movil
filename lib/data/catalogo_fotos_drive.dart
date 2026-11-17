/// Código de producto -> ID de su foto en la carpeta compartida de Drive.
/// Solo contiene referencias; las imágenes se cargan por Internet.
const catalogoFotosDrive = <String, String>{
  'EL-001': '18sTo0TdimGbaQTaoWO3I-5CeTbXW5yMu',
  'EL-002': '11TQOWBfpmR0YTMIx9mqKqS-iGk21t_h7',
  'EL-003': '1EpYC6u1oxanF0rVBVJ0U4c9WVamqxXbS',
  'EL-004': '1MMHa2yql5uwsiV5GpG7VD9Ib9MHG_Kfv',
  'EX-001': '1xZe_32MBcgOdFznJMKH1sv9ZKrD2Apv3',
  'EX-002': '1wHuK5djF4iW71Fh2e3f-b-lzAy9BCvYa',
  'EX-003': '1nkgUo7krol_d_xcyGFTUghmTkpwrDXVt',
  'EX-004': '1exSxo_Hu_SgP_TH1FGDqNg1D59X_BbG9',
  'EX-005': '1lBPF5cmkvFk7vB744tUj-Yq1OsdQsEhi',
  'EX-006': '1G4AAfQw1shctPHXjgag4hfA6k86LwRPw',
  'EX-007': '1wtjnf8bDetuRsoCVINPVFgcce_Z7ERbV',
  'GF-001': '1pdVO8ycEZVTjVejIiB7ROd_rOVhjTpho',
  'GF-002': '1TOrv47MdqHfL3ICWgcaiHmt_av0FD5if',
  'GF-003': '17PP5IqL8MpWlPEhNVzC-RgFg4vbbHqvB',
  'GF-004': '1LqxHeBTI6vwz2Uzj91z70aSYucynwMB8',
  'HE-001': '1ER-4ay3WE0Dm7v5m73iunuqeDF6OZrMk',
  'HE-002': '1dJpCZhFIMmiCItl4nyycpQsnAJ5sTSuE',
  'HE-003': '1MEII71Y3DbFZZbT8zETk4BuMJfXKT7cr',
  'HE-004': '140ltZU3m0S00my0TQ86TVprR6apFnfAG',
  'HER-001': '1dX77hYvwzaYShizJQGnLGv7odyib790A',
  'HER-003': '1Wy9XFK3VnG3aA39V5oiqm_zSryGthEJp',
  'HER-004': '16rLnAwb8zyyCz7hZCK8DWU-AD0x4oA27',
  'HM-001': '1IDS2G7fXKsWja-c0i2MB4Ox0VYZvTfwo',
  'HM-002': '1c2FWZikO5z2UkjFm15xreJpOOF7cBzg3',
  'HM-003': '1kainlNZK7M5sLAx0VYO3J81t2q-9Mr-o',
  'HM-004': '1kItIiOZGpJ_enhq_CAh7iK8E7aNyZtMU',
  'HM-005': '1jzqMZlOshHc93q52TpRA5-P3LL6TaJYw',
  'MC-001': '1E7pSuzMi7AKRC1_FVzVxF_ImkUZ20Q3B',
  'MC-002': '1uJxR1Zq06Yn0b8V-FFFaCRAiL232DyrJ',
  'MC-003': '1dovaEvFPR5WT6oOGMqnQmsGTmR_v-iYb',
  'MC-004': '1kJHc1YWhlxim7m2QG5bQSc16yICG3-qV',
  'PA-001': '1RTv2RjTiTJ1jWXRb7RkI_n-TBTsIIEfx',
  'PA-002': '1C5bMlQY-fg0wqWANLvwNByVcdfKHZQ5b',
  'PA-003': '192ZHnOx9W_w51TpworZdo3mc_n3igAyD',
  'PA-004': '18_wajvC6BudH6DtrF5tIeartBWLHx0eT',
  'SI-001': '1JHd7bKLRrivyUZdxdNhOX7-nlK6xiZZ4',
  'SI-002': '1yQWUSATLuIlhMZYIOstPFd1xl8RncQM4',
  'SI-003': '1ZCKPtPistHCLMCK7FRznNNGlyNXBL63m',
  'SI-004': '1SsO0o7rS2JYpoP_0kBFNdfFD-iyGBuEe',
  'TF-001': '1RRQpncZrC9pTGvMIlz8curF3YdE-kLXp',
  'TF-002': '166gUqdEOS8yj-KsFliki864QLpLF6jq4',
  'TF-003': '1bUeLl_aii6AVgA73MmMQgrlxgO9vkCsC',
  'TF-004': '1MEwD3tjg4AMHUJXLAovvaQ3UME-hJ81y',
};

/// Equivalencias verificadas entre el catálogo de la app y las carpetas.
/// No cambia los códigos de inventario ni los documentos de Firestore.
const equivalenciasFotosDrive = <String, String>{
  'HER-002': 'EX-001', // Juego de llaves mixtas.
  'HER-006': 'HM-003', // Alicate.
  'HER-007': 'HM-004', // Llave ajustable.
  'HER-008': 'HM-002', // Juego de destornilladores.
  'HER-011': 'HE-004', // Taladro inalámbrico.
  'PIN-001': 'PA-001', // Pintura látex.
  'PIN-003': 'PA-003', // Rodillo.
  'PIN-004': 'PA-002', // Brocha.
  'PIN-008': 'PA-004', // Thinner.
  'TUB-001': 'GF-001', // Tubería PVC.
  'TUB-002': 'GF-002', // Codo PVC 90 grados.
  'ELE-001': 'EL-001', // Cable THW.
  'ELE-002': 'EL-002', // Interruptor sencillo.
  'ELE-007': 'EL-003', // Tomacorriente doble.
  'CEM-001': 'MC-001', // Cemento Sol.
  'CEM-002': 'MC-004', // Fierro corrugado.
  'CEM-008': 'EX-005', // Alambre negro.
  'CTO-001': 'TF-001', // Clavos de acero.
  'CTO-002': 'TF-002', // Tornillos drywall.
  'CTO-003': 'EX-007', // Clavos de calamina.
  'CTO-004': 'TF-001', // Clavos para madera.
  'CTO-006': 'TF-003', // Tarugos.
  'CTO-007': 'TF-004', // Pernos con tuerca.
};
