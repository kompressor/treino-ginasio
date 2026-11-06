# Jorge Verde — mostrador para Forerunner 965

Horas e minutos grandes, em gradiente (verde-lima → verde), sem segundos nem dois pontos, data em português e indicadores com ícones em gradiente.

| Zona | Dado |
|---|---|
| Topo | Bateria % |
| Data | Dia da semana (3 letras) e dia do mês (ex.: SEX 6) |
| Centro | Horas (branco → verde claro) e minutos (lima → verde) |
| Indicadores | Tempo de recuperação (h), altitude (m), pressão atmosférica (hPa), distância do dia (km) |

No modo sempre-ligado mostra só hora e data, em cinzento e a mudar ligeiramente de posição (protecção do ecrã AMOLED).

Tipo de letra: Barlow Condensed (SIL Open Font License). Ícones: Tabler Icons (MIT).

## Compilar no GitHub

1. Cria um repositório (pode ser privado) e envia estes ficheiros.
2. Em *Settings → Secrets and variables → Actions* cria:
   - `GARMIN_USERNAME` — e-mail da conta Garmin
   - `GARMIN_PASSWORD` — palavra-passe da conta Garmin
   - (opcional) `GARMIN_AGREEMENT_HASH` — só se o passo da licença falhar a pedir o hash
   - (opcional) `DEVELOPER_KEY_B64` — chave própria em base64; sem ela é gerada uma nova a cada compilação
3. Em *Actions* corre **Compilar mostrador** e descarrega o artefacto `JorgeVerde-fr965` (contém `JorgeVerde.prg`).

O SDK da Garmin só se descarrega com sessão iniciada; se a conta tiver verificação em dois passos, o login automático pode falhar.

## Instalar no relógio

1. Liga o FR965 ao computador por USB.
2. Copia `JorgeVerde.prg` para a pasta `GARMIN/APPS`.
3. Desliga o cabo; no relógio: *Mostrador → Jorge Verde*.
