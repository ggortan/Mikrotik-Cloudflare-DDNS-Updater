# ====================================================================
# MIKROTIK CLOUDFLARE DDNS UPDATER - NATIVE INTERFACE MODE
# ====================================================================
# Author: Gabriel Gortan (Based on community scripts)
# Description: Updates Cloudflare DNS A Records based on Mikrotik Interface IP
# Tested on: RouterOS v7.x
# ====================================================================

## ---- Configuration / Configuração -----

# 1. Interface Name / Nome da Interface
# PT: Defina o NOME EXATO da interface que recebe o IP Público (ex: pppoe-out1, ether1)
# EN: Set the EXACT NAME of the interface receiving the Public IP
:local WanInterface "pppoe-out1"

# 2. Cloudflare Settings / Dados da Cloudflare
# PT: Preencha com seus dados. Você pode adicionar múltiplas entradas.
# EN: Fill with your data. You can add multiple entries.
:local ParamVect {
    "meu.dominio.com"={
        "DnsZoneID"="_____COLE_SUA_ZONE_ID_AQUI_____";
        "DnsRcrdID"="_____COLE_SEU_RECORD_ID_AQUI_____";
        "AuthToken"="_____COLE_SEU_API_TOKEN_AQUI_____";
        "Proxied"=false; 
    };
    # "vpn.outrodominio.com"={ ... };
}

# 3. Logging
# PT: Habilitar logs detalhados para debug? (true/false)
:local VerboseLog false

## ---- End of Configuration / Fim da Configuração ----

:global WanIP4Cur

:do {
    # Busca o IP atribuído à interface especificada
    :local CurrentIpCidr
    :do {
        :set CurrentIpCidr [/ip address get [find interface=$WanInterface disabled=no] address]
    } on-error={ 
        :log error "[CF-DDNS] Erro: Interface $WanInterface não encontrada ou sem IP."
        :error "Stop" 
    }

    # O Mikrotik retorna o IP com a máscara (ex: 200.1.1.1/32).
    # Precisamos remover o "/xx" para pegar apenas o IP limpo.
    :local SlashPos [:find $CurrentIpCidr "/"]
    :local WanIP4New [:pick $CurrentIpCidr 0 $SlashPos]

    # Validação simples se obteve algo
    :if ([:len $WanIP4New] > 0) do={
        
        # Verifica se mudou em relação à memória global
        :if ($WanIP4New != $WanIP4Cur) do={
            :log warning "[CF-DDNS] IP da Interface $WanInterface mudou: $WanIP4Cur -> $WanIP4New"
            
            :foreach fqdn,params in=$ParamVect do={
                :local DnsZoneID ($params->"DnsZoneID")
                :local DnsRcrdID ($params->"DnsRcrdID")
                :local AuthToken ($params->"AuthToken")
                :local Proxied   ($params->"Proxied")
                
                :local Url "https://api.cloudflare.com/client/v4/zones/$DnsZoneID/dns_records/$DnsRcrdID/"
                
                :if ($VerboseLog) do={ :log info "[CF-DDNS] Atualizando $fqdn..." }

                # Envia atualização via PUT
                :local CfApiResult [/tool fetch http-method=put mode=https url=$Url check-certificate=yes output=user as-value \
                    http-header-field="Authorization: Bearer $AuthToken,Content-Type: application/json" \
                    http-data="{\"type\":\"A\",\"name\":\"$fqdn\",\"content\":\"$WanIP4New\",\"ttl\":120,\"proxied\":$Proxied}"]
                
                :if ($CfApiResult->"status" = "finished") do={
                    :log warning "[CF-DDNS] Sucesso: $fqdn atualizado para $WanIP4New"
                } else={
                    :log error "[CF-DDNS] Falha API Cloudflare para $fqdn"
                }
                :delay 1s
            }
            
            # Atualiza variavel global
            :set WanIP4Cur $WanIP4New
            
        } else={
            :if ($VerboseLog) do={ :log info "[CF-DDNS] IP Nativo mantido ($WanIP4New)." }
        }
    }
} on-error={
    :log error "[CF-DDNS] Erro fatal na execução."
}
