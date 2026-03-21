# Arquitectura (Mermaid)

Estado actual (privado por Tailscale, sin exposición pública 80/443):

```mermaid
flowchart LR
  subgraph Internet["Internet público"]
    PUB[Clientes públicos]
  end

  subgraph Tailnet["Tailnet (Tailscale)"]
    MOBIL[Móvil/PC autorizados]
    TSURL["https://<node>.ts.net"]
  end

  subgraph VPS["VPS VareIA"]
    TSERVE["tailscale serve :443"]
    LOOP["127.0.0.1:8080 (host)"]

    subgraph Docker["Docker"]
      RP["reverse-proxy-nginx<br/>proxy-net + infra-net"]
      N8N["automation-n8n<br/>infra-net"]
      PG["postgres-shared<br/>infra-net"]
    end
  end

  PUB -. 80/443 cerrados .-> VPS
  MOBIL --> TSURL --> TSERVE --> LOOP --> RP --> N8N --> PG
```

Notas:
- `reverse-proxy-nginx` no publica puertos públicos; solo binding local `127.0.0.1:8080`.
- El acceso web operativo se realiza por Tailscale Serve (`*.ts.net`).
- `n8n` y `postgres` permanecen internos en `infra-net`.
