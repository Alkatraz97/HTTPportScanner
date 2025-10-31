#!/bin/bash

# Nome del file contenente gli host (uno per riga)
HOSTS_FILE="hosts.txt"

# Lista delle porte comuni HTTP/HTTPS da scansionare
PORTS=(80 81 443 8000 8080 8081 8081 8008 4443 8443 9090 9091 9092)

# Tempo massimo di timeout per la connessione (in secondi)
TIMEOUT=2

# Funzione per eseguire la scansione su un host e una porta specifici
scan_port() {
    local host=$1
    local port=$2
    local protocol=""
    local url=""
    local response_code=""

    # Determina il protocollo in base alla porta (semplificazione)
    if [[ "$port" -eq 443 || "$port" -eq 8443 ]]; then
        protocol="https"
    else
        protocol="http"
    fi

    url="${protocol}://${host}:${port}"

    # Esegue la richiesta cURL
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -m $TIMEOUT --connect-timeout $TIMEOUT --max-redirs 0 "$url" 2>/dev/null)

    # Verifica se cURL ha stabilito una connessione HTTP/HTTPS (codici di successo, reindirizzamento, o errore lato client/server)
    if [[ -n "$response_code" ]] && [[ "$response_code" != "000" ]]; then
        echo "$host risponde sulla porta $port ($protocol) con codice $response_code"
        echo "$port"
    fi
}

# Array per memorizzare i risultati
declare -A OPEN_PORTS

echo "--- 🕵️ Inizio Scansione cURL per Red Team 🕵️ ---"

# Verifica l'esistenza del file hosts.txt
if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Errore: File '$HOSTS_FILE' non trovato."
    echo "Crea il file e inserisci gli IP/nomi host, uno per riga."
    exit 1
fi

# Ciclo sugli host nel file
while IFS= read -r host || [[ -n "$host" ]]; do
    # Salta le righe vuote o commentate
    if [[ -z "$host" || "$host" =~ ^# ]]; then
        continue
    fi
    
    echo ""
    echo "--- Scansione di $host ---"
    OPEN_PORTS["$host"]="" # Inizializza l'elenco delle porte aperte per l'host

    # Ciclo sulle porte
    for port in "${PORTS[@]}"; do
        
        # Genera un ritardo casuale tra 50 e 120 secondi
        # $RANDOM genera un numero tra 0 e 32767. L'aritmetica Bash genera un valore tra 0 e 70, a cui si aggiunge 50.
        RANDOM_DELAY=$(( RANDOM % 71 + 50 ))
        
        echo "⏳ Attesa casuale di ${RANDOM_DELAY} secondi prima di testare la porta $port su $host..."
        sleep "$RANDOM_DELAY"
        
        echo "Testing $host:$port..."
        
        # Esegui la scansione e memorizza l'output della porta (che è l'unica cosa che la funzione stampa su stdout)
        PORT_RESULT=$(scan_port "$host" "$port")

        if [[ -n "$PORT_RESULT" ]]; then
            # Estrai solo il numero di porta dal risultato
            PORT_NUMBER=$(echo "$PORT_RESULT" | tail -n 1)
            # Aggiungi la porta all'elenco
            OPEN_PORTS["$host"]="${OPEN_PORTS["$host"]}$PORT_NUMBER "
        fi
    done
    
done < "$HOSTS_FILE"

# --- 🎯 Output dei Risultati 🎯 ---

echo ""
echo "============================================"
echo "      RIEPILOGO DEI RISULTATI DELLA SCANSIONE"
echo "============================================"

# Stampa i risultati
for host in "${!OPEN_PORTS[@]}"; do
    if [[ -n "${OPEN_PORTS["$host"]}" ]]; then
        echo "**Host:** $host"
        echo "**Porte HTTP/HTTPS:** ${OPEN_PORTS["$host"]}"
        echo "--------------------------------------------"
    else
        echo "**Host:** $host"
        echo "**Porte HTTP/HTTPS:** Nessuna porta ha risposto"
        echo "--------------------------------------------"
    fi
done

echo "--- 🏁 Scansione Terminata 🏁 ---"
