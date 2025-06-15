// 🧪 PRUEBA SIMPLE DE GMAIL
// Crear un archivo test-gmail.js en la carpeta functions/

const nodemailer = require('nodemailer');

// Configuración con la nueva App Password
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'paddlepapudo@gmail.com',
    pass: 'yyll uhje izsv mbwc'  // La nueva App Password
  },
  tls: {
    rejectUnauthorized: false
  }
});

// Función simple de prueba
async function testGmail() {
  console.log('🧪 Iniciando prueba de Gmail...');
  
  try {
    // 1. Verificar conexión
    console.log('📡 Verificando conexión SMTP...');
    await transporter.verify();
    console.log('✅ Conexión SMTP exitosa');
    
    // 2. Enviar email de prueba
    console.log('📧 Enviando email de prueba...');
    const info = await transporter.sendMail({
      from: 'paddlepapudo@gmail.com',
      to: 'paddlepapudo@gmail.com', // Enviar a sí mismo para prueba
      subject: '🧪 Test de Gmail - Club Pádel Papudo',
      html: `
        <h2>✅ Test Exitoso</h2>
        <p>Este email confirma que Gmail está funcionando correctamente.</p>
        <p><strong>Fecha:</strong> ${new Date().toLocaleString()}</p>
        <p><strong>App Password:</strong> Funcionando ✅</p>
      `
    });
    
    console.log('✅ Email enviado exitosamente!');
    console.log('📧 Message ID:', info.messageId);
    console.log('🎯 Response:', info.response);
    
  } catch (error) {
    console.error('❌ Error en la prueba:');
    console.error('Código de error:', error.code);
    console.error('Mensaje:', error.message);
    console.error('Error completo:', error);
  }
}

// Ejecutar la prueba
testGmail();

// INSTRUCCIONES PARA USAR:
// 1. Guardar como functions/test-gmail.js
// 2. cd functions
// 3. node test-gmail.js
//
// RESULTADOS ESPERADOS:
// ✅ Si funciona: "Email enviado exitosamente" + Message ID
// ❌ Si falla: Error específico con código y mensaje