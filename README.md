# Mikrotik Cloudflare DDNS (Native Interface)

Script simples e eficiente para atualizar registros DNS da Cloudflare usando Mikrotik RouterOS. 

Diferente da maioria dos scripts que dependem de serviços externos (como `checkip.amazonaws.com`) para descobrir o IP público, **este script lê o IP diretamente da interface WAN do Mikrotik**.

### Vantagens
* **Mais Rápido:** Não há latência de requisição HTTP para checar o IP.
* **Mais Confiável:** Não para de funcionar se o serviço de "check ip" sair do ar.
* **Seguro:** Verifica certificados SSL da Cloudflare.
* **Flexível:** Suporta Proxy da Cloudflare (Nuvem Laranja) ligado ou desligado.

---

### Requisitos
1.  **RouterOS v6.4x ou v7.x**.
2.  **IP Público na Interface:** Sua interface WAN (ex: `pppoe-out1`) deve receber um IP Público. 
    * *Nota: Se o seu provedor usa CGNAT (IPs 100.64.x.x, 10.x.x.x), este script NÃO funcionará para acesso externo.*
3.  **Token da API Cloudflare:** Com permissão de edição de DNS (`Zone.DNS` -> `Edit`).

---

### Configuração

#### 1. Obter IDs da Cloudflare
Você precisará do `Zone ID` (disponível na página inicial do domínio na Cloudflare) e do `Record ID` (ID específico do subdomínio que deseja atualizar).

Para descobrir o `Record ID`, rode este comando no terminal do seu computador (ou no Mikrotik):
```bash
curl -X GET "[https://api.cloudflare.com/client/v4/zones/SEU_ZONE_ID/dns_records](https://api.cloudflare.com/client/v4/zones/SEU_ZONE_ID/dns_records)" \
     -H "Authorization: Bearer SEU_API_TOKEN" \
     -H "Content-Type: application/json"
