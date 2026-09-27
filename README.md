# The Turing Test — PT-BR Completo

Tradução completa para português do Brasil da versão de PC/Windows de **The Turing Test**, com menus traduzidos, legendas maiores e instalador automático.

O pacote mantém os diálogos e as legendas em português já disponíveis nos arquivos de texto do jogo e completa as partes que ainda permaneciam em inglês, incluindo os menus principais e as configurações.

## Baixar

Baixe a versão mais recente na página de [lançamentos do projeto](https://github.com/adestrador/the-turing-test-ptbr-completo/releases/latest).

Não use o botão **Baixar ZIP** do repositório para instalar. O arquivo correto fica em **Lançamentos**, com o nome:

`The_Turing_Test_PTBR_Completo_v1.0.zip`

## Recursos

- Diálogos, legendas e textos em português do Brasil.
- Menu principal traduzido.
- Menu de pausa e telas de confirmação traduzidos.
- Configurações de vídeo, áudio, controles e jogabilidade traduzidas.
- Mensagens e telas de carregamento traduzidas.
- Fonte das legendas aumentada de 14 para 21, ficando 50% maior.
- Detecção automática da pasta do jogo e das bibliotecas comuns da Steam.
- Backup e restauração automáticos.
- Verificação de compatibilidade antes de modificar qualquer arquivo.
- Instalação testada em 1920×1080.

## Capturas de tela

### Menu principal traduzido

![Menu principal de The Turing Test traduzido para português do Brasil](docs/imagens/01-menu-principal.png)

### Tradução e legendas maiores durante o jogo

| Início do jogo | Diálogo com texto longo |
| --- | --- |
| ![Legenda em português no início do jogo](docs/imagens/02-legendas-inicio.png) | ![Legenda longa em português durante o jogo](docs/imagens/03-legendas-dialogo.png) |

## Compatibilidade

- Plataforma: PC/Windows.
- Versão analisada: arquivos da edição de PC disponíveis em 26/09/2026.
- Resolução usada nos testes: 1920×1080.
- O jogo original precisa estar instalado.

O instalador confere o executável e todos os recursos que serão modificados. Se encontrar uma versão diferente ou outro mod incompatível, encerrará o processo antes de escrever nos arquivos do jogo.

## Instalação

1. Baixe `The_Turing_Test_PTBR_Completo_v1.0.zip` na página de lançamentos.
2. Extraia todo o conteúdo do ZIP para uma pasta comum.
3. Feche o jogo.
4. Execute `INSTALAR.bat`.
5. Confira a pasta detectada e pressione **Enter**.
6. Caso a pasta esteja incorreta, digite manualmente o caminho principal do jogo.
7. Aguarde a mensagem de instalação concluída.

Exemplos de pastas válidas:

```text
C:\The Turing Test
C:\Program Files (x86)\Steam\steamapps\common\The Turing Test
D:\SteamLibrary\steamapps\common\The Turing Test
```

> Não execute o instalador diretamente de dentro do ZIP.

## Restauração

1. Feche o jogo.
2. Execute `RESTAURAR.bat`.
3. Selecione a mesma pasta usada durante a instalação.

O backup fica armazenado na pasta:

```text
Backup_PTBR_Completo_v1
```

Não apague essa pasta enquanto quiser manter a possibilidade de restauração.

## Observações

Algumas palavras gravadas diretamente no executável aparecem sem acentos, como `OPCOES`, `CAPITULOS` e `NAO`. Essa limitação evita caracteres corrompidos no mecanismo antigo usado pelo jogo.

Se a Steam verificar ou atualizar os arquivos, pode ser necessário instalar o pacote novamente.

## Segurança do pacote

O repositório não distribui o executável original nem os arquivos completos de recursos do jogo. O instalador contém os textos em português e pequenas diferenças binárias aplicadas sobre uma cópia legítima instalada.

SHA-256 do instalador da versão 1.0:

```text
65cc6aeccfc1d35fe461ad384d20bdced0785ac9073fbb9114d2b816dc918e6b
```

## Problemas

Antes de relatar um erro:

1. Confirme que o jogo está fechado.
2. Extraia novamente o ZIP.
3. Verifique se informou a pasta principal do jogo.
4. Consulte [SUPORTE.md](SUPORTE.md).

Se o problema continuar, abra um relato na seção **Problemas** do repositório e anexe `resultado_instalar.txt`.

## Créditos

Projeto organizado e publicado por [tigerwong](https://github.com/adestrador).

Este é um projeto de fã, gratuito e sem afiliação com os desenvolvedores ou publicadores de **The Turing Test**.

Consulte o [aviso legal](AVISO-LEGAL.md) antes de redistribuir o pacote.

O registro das alterações está no [histórico de versões](HISTORICO-DE-VERSOES.md).
