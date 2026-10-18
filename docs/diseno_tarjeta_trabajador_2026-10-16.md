# Tarjeta del trabajador

La cabecera usa un fondo suave con volver, editar y activar/desactivar alineados en una misma fila. El avatar queda junto al nombre, con los nombres arriba, apellidos debajo y cargo al final.

Los datos se presentan en filas compactas con iconos discretos y etiquetas secundarias. Se separan contacto, asignación laboral e identificador. Todos los valores siguen visibles y seleccionables, sin truncar el correo ni el identificador.

El ajuste tipográfico posterior diferencia nombres (17, negrita), apellidos (16, seminegrita), etiquetas (13, negrita y azul oscuro #123847 de la última muestra proporcionada) y valores (13, peso normal y tono oscuro). Se eliminó el espaciado adicional entre letras y se ajustó el interlineado. El identificador usa tamaño 12. Se respeta el aumento de texto del dispositivo.

Se mantienen los callbacks y sus estados habilitados. Validado con las pruebas de navegación y de ficha a 320, 768 y 1280 píxeles, texto normal y al doble, más una captura local con datos de prueba.

Última corrección: la nueva muestra vuelve a ser #007F91. Se aplica ese color explícito a las etiquetas y se aumenta su peso a 900 para que la negrita sea más marcada. Los valores conservan tamaño 13 y peso normal.
