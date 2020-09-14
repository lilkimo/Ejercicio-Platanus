require 'httparty'
require 'time'
require 'json'

# Constantes
raiz = 'https://www.buda.com/api/v2'
tiempoActual = (Time.now.to_f * 1000).to_i # Tiempo actual en milisegundos.
limiteTemporal = tiempoActual - (1000 * 60 * 60 * 24) # Tiempo actual - 24 horas (En milisegundos).
#/

# Obtener Mercados
rama = '/markets'
respuesta = HTTParty.get(raiz + rama, format: :plain)
mercadosCrudo = JSON.parse(respuesta)['markets']

mercados = []
mercadosCrudo.each do |mercado|
    mercados.push(mercado['id'])
end
#/

# Mayor monto en las últimas 24 horas
puts "+---------+-------------------+\n| Mercado | Mayor transacción |\n+---------+-------------------+"
## Nota: Podría haber puesto todo este segmento de código dentro del bucle .each anterior, pero lo preferí de
#  esta forma para favorecer la limpieza del código.
mercados.each do |mercado|
    rama = "/markets/#{mercado}/trades"
    montoMaximo = -1
    ultimaTransaccion = tiempoActual

    loop do
        respuesta = HTTParty.get(raiz + rama, query: {timestamp: ultimaTransaccion, limit: 100}, format: :plain)
        transaccionesCrudo = JSON.parse(respuesta)['trades']
        
        transacciones = transaccionesCrudo['entries']
        transacciones.each do |transaccion|
            # Según la API de buda.com; una transacción es de la forma [fecha, monto, precio, dirección].
            fecha = transaccion[0].to_i
            break if fecha < limiteTemporal # Como las transacciones se ordenan cronológicamente paro de buscar
                                            #  apenas encuentre una que sucedió antes de la fecha límite.
            monto = transaccion[1].to_f
            montoMaximo = monto if monto > montoMaximo
        end
        
        ultimaTransaccion = transaccionesCrudo['last_timestamp'].to_i
        break if ultimaTransaccion < limiteTemporal
    end

    if montoMaximo != -1
        # Los espacios restantes completar la cuadricula.
        espacios = ' ' * (12 - montoMaximo.to_s.length) if 12 - montoMaximo.to_s.length >= 0
        
        puts "| #{mercado} | #{montoMaximo} #{mercado[0, 3]} #{espacios} |"
    else
        puts "| #{mercado} | Sin transacciones |"
    end
end
puts '+---------+-------------------+'
#/