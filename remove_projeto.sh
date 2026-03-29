#!/usr/bin/bash

# Define o Token e a URL (ajuste se necessário)
TOKEN="dt_0fer9gMt_08x2CcnVl663ICpzKf16ueW3Baf8YgqQ"
URL="http://localhost:8090/api/v1/project"

# Loop para deletar cada projeto encontrado
for uuid in $(curl -s -H "X-Api-Key: $TOKEN" $URL | jq -r '.[].uuid'); do
    echo "Deletando projeto: $uuid"
    curl -s -X DELETE -H "X-Api-Key: $TOKEN" "$URL/$uuid"
done

echo "✅ Faxina concluída!"
