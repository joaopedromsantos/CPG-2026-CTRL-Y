# CPG_CTRL_Y - Math Runner

Jogo 3D feito em Godot no estilo endless runner educativo. O jogador controla um robô em três faixas, escolhe blocos com respostas para equações e usa power-ups para sobreviver, pontuar mais ou facilitar as respostas.

## Status do Projeto

O projeto possui um ciclo de jogo funcional:

- tela inicial com botão de começar, botão de configurações e seletor de dificuldade;
- modal de configurações com volume de música e efeitos sonoros;
- persistência local de recorde e preferências do jogador;
- jogo principal em 3D;
- geração de equações por dificuldade;
- blocos de resposta nas três pistas;
- obstáculos, power-ups, pontuação, vidas, cronômetro e feedback visual;
- pausa e tela de fim de jogo.

## Requisitos

- Godot 4.6 ou compatível com `config/features=PackedStringArray("4.6", "Forward Plus")`.
- Renderizador Forward Plus.
- Física 3D com Jolt Physics.

## Como Rodar

1. Abra o Godot.
2. Importe a pasta do projeto.
3. Abra `project.godot`.
4. Execute o projeto.

A cena inicial configurada é:

```text
res://scenes/start_screen.tscn
```

## Gameplay

O jogo é um runner 3D com três pistas. O personagem corre automaticamente e o jogador muda de faixa para escolher uma das respostas que aparecem em blocos à frente.

No topo da tela aparece uma equação. Quando uma linha de blocos chega até o jogador, a faixa ocupada pelo personagem define a resposta escolhida.

Se a resposta estiver correta:

- ganha pontos;
- toca som de acerto;
- mostra feedback positivo;
- carrega uma nova equação.

Se a resposta estiver errada ou o jogador bater em um cone:

- perde uma vida;
- toca som de erro/impacto;
- mostra feedback negativo;
- carrega uma nova equação quando aplicável.

O jogo termina quando as vidas chegam a zero, exceto se houver um revive ativo disponível.

## Controles

| Ação | Teclas/UI |
| --- | --- |
| Mover para a esquerda | `Seta esquerda` ou `A` |
| Mover para a direita | `Seta direita` ou `D` |
| Pular | `Espaço` |
| Usar power-up do slot 1 | `1` |
| Usar power-up do slot 2 | `2` |
| Usar power-up do slot 3 | `3` |
| Reiniciar após game over | `R` |
| Começar na tela inicial | `Enter` ou botão `Começar` |
| Selecionar dificuldade | setas `<` e `>` na tela inicial |
| Abrir configurações | botão com ícone de cog |
| Fechar configurações | botão `X` no modal |
| Pausar/continuar | botão de pausa no HUD |

## Dificuldades

A tela inicial usa um seletor com setas e badge central. As dificuldades são salvas nas preferências do usuário assim que são alteradas.

| Rótulo | Valor interno | Cor da badge |
| --- | --- | --- |
| Fácil | `easy` | verde |
| Médio | `medium` | azul |
| Difícil | `hard` | laranja |
| Impossível | `impossible` | vermelho |

As perguntas vêm de `data/equations.json`, com 260 questões:

- 70 fáceis;
- 70 médias;
- 60 difíceis;
- 60 impossíveis.

## Configurações

O modal de configurações fica em:

```text
scenes/settings_screen.tscn
scripts/screens/settings/settings_screen.gd
```

Ele permite alterar:

- volume da música, de `0` a `10`;
- volume dos efeitos sonoros, de `0` a `10`.

Botões do modal:

- `Salvar`: persiste os volumes atuais e fecha o modal;
- `Resetar`: volta música e efeitos para `10/10`, salva e reaplica a música;
- `X`: fecha o modal sem salvar mudanças pendentes.

As preferências são gerenciadas pelo autoload `GameSettings` e salvas em:

```text
user://game_settings.cfg
```

Valores padrão quando não há configuração salva:

- volume da música: `10`;
- volume dos efeitos sonoros: `10`;
- dificuldade: `easy`.

## Sistema de Equações

As equações são carregadas por `scripts/equations/equation_sequence.gd`.

Funcionalidades:

- leitura de `data/equations.json`;
- validação básica dos campos das questões;
- filtro por dificuldade selecionada;
- embaralhamento das perguntas;
- fila de 3 equações;
- embaralhamento das opções de cada questão.

Formato geral:

```json
{
  "difficulty": "easy",
  "topic": "addition_missing",
  "type": "single_answer",
  "equation": "5 + 🟨 = 6",
  "correctAnswers": [1],
  "options": [
    { "value": 1, "isCorrect": true },
    { "value": 0, "isCorrect": false },
    { "value": 2, "isCorrect": false }
  ]
}
```

## Pontuação e Vidas

O jogador começa com 3 vidas.

Regras atuais:

- cada resposta correta soma 1 ponto;
- com power-up `double` ativo, cada acerto soma 2 pontos;
- cada erro remove 1 vida;
- bater em cone remove 1 vida;
- ao chegar a 0 vidas, o jogo termina;
- se o power-up `revive` estiver ativo quando as vidas chegam a 0, ele é consumido e o jogador volta com 1 vida.

A velocidade do mundo começa em `8.0` e aumenta com a pontuação:

```text
velocidade = 8.0 + pontuação * 0.2
```

O power-up `hourglass` reduz temporariamente essa velocidade.

## Power-ups

Os power-ups aparecem na pista com chance periódica de spawn. Ao encostar no jogador, eles entram nos slots do HUD.

Existem 4 slots visuais:

- slots 1, 2 e 3 são ativáveis pelas teclas `1`, `2` e `3`;
- o quarto slot funciona como reserva;
- quando um efeito termina, o item da reserva é movido para o slot liberado.

| Power-up | Duração | Efeito |
| --- | ---: | --- |
| `lupa` | 6s | destaca visualmente os blocos com resposta correta |
| `revive` | 10s | evita a morte uma vez, restaurando 1 vida quando as vidas chegam a 0 |
| `heart` | 5s | cura 1 vida ao ativar e cura novamente a cada 2s enquanto ativo |
| `lightning` | 5s | resolve automaticamente as linhas como corretas |
| `hourglass` | 6s | reduz a velocidade do mundo para 55% |
| `double` | 8s | dobra a pontuação recebida em acertos |

Configuração:

```text
assets/power-ups/power_up_config.tres
scripts/power_ups/power_up_config.gd
```

## HUD

O HUD exibe:

- equação atual;
- feedback de acerto ou erro;
- pontuação;
- vidas com corações cheios/vazios;
- cronômetro em `MM:SS`;
- botão de pausa;
- slots de power-up com ícones;
- contagem regressiva dos power-ups ativos;
- tela de game over com pontuação e tempo.

## Telas

### Tela Inicial

Arquivo:

```text
scenes/start_screen.tscn
```

Funcionalidades:

- título `MATH RUNNER`;
- arte procedural em estilo neon;
- música de menu em loop;
- exibição do high score;
- botão `Começar`;
- botão de configurações com ícone de cog;
- seletor de dificuldade com setas;
- modal de configurações instanciado sobre a própria tela inicial.

### Configurações

Arquivo:

```text
scenes/settings_screen.tscn
```

Funcionalidades:

- controle de volume da música;
- controle de volume dos efeitos sonoros;
- botão `Salvar`;
- botão `Resetar`;
- botão `X` para fechar.

### Jogo Principal

Arquivo:

```text
scenes/main.tscn
```

Responsável por instanciar e conectar:

- cenário;
- jogador;
- blocos de resposta;
- power-ups;
- cones;
- controlador de efeitos;
- HUD;
- áudio do jogo.

### Fim de Jogo

Arquivo:

```text
scenes/end_game_screen.tscn
```

Mostra:

- mensagem de morte;
- pontuação final;
- tempo final;
- botão `Jogar novamente`;
- botão `Tela inicial`;
- botão `Sair do jogo`.

## Persistência Local

Recorde:

```text
user://player_record.cfg
```

Preferências:

```text
user://game_settings.cfg
```

Autoloads configurados em `project.godot`:

```text
PlayerRecord="*res://scripts/player/record/player_record.gd"
GameSettings="*res://scripts/settings/game_settings.gd"
```

## Áudio

O projeto possui sons para:

- música de menu;
- música do jogo;
- pulo;
- acerto;
- erro/impacto;
- derrota;
- coleta e bônus.

Arquivos principais:

```text
assets/sounds/menu_sound.wav
assets/sounds/game_sound.wav
assets/sounds/jump_sound.wav
assets/sounds/bonus_sound.wav
assets/sounds/punch_sound.wav
assets/sounds/losing_sound.wav
```

Volumes são aplicados por categoria:

- música: menu e música do jogo;
- efeitos: pulo, acerto, erro, impacto e derrota.

## Estrutura Principal

```text
.
├── assets/
│   ├── car-kit/
│   ├── city-kit-roads/
│   ├── fonts/
│   ├── hud/
│   ├── player/
│   ├── power-ups/
│   ├── sounds/
│   └── tiles/
├── data/
│   └── equations.json
├── scenes/
│   ├── end_game_screen.tscn
│   ├── hud.tscn
│   ├── main.tscn
│   ├── pause_screen.tscn
│   ├── player.tscn
│   ├── settings_screen.tscn
│   └── start_screen.tscn
├── scripts/
│   ├── blocks/
│   ├── equations/
│   ├── game/
│   ├── hud/
│   ├── obstacles/
│   ├── player/
│   ├── power_ups/
│   ├── ranking/
│   ├── scenario/
│   ├── screens/
│   ├── settings/
│   └── timer/
├── project.godot
└── README.md
```

## Scripts Principais

| Arquivo | Função |
| --- | --- |
| `scripts/game/main.gd` | controla ciclo principal, pontuação, vidas, pausa, áudio, game over e conexões entre sistemas |
| `scripts/player/player.gd` | controla o personagem, pistas, pulo e animações |
| `scripts/blocks/blocks.gd` | gera blocos de resposta, resolve a resposta escolhida e emite acerto/erro |
| `scripts/obstacles/cones.gd` | gera obstáculos e detecta colisão com o jogador |
| `scripts/scenario/scenario.gd` | cria e atualiza o cenário 3D |
| `scripts/power_ups/power_ups.gd` | gera power-ups na pista e detecta coleta |
| `scripts/power_ups/effects/power_up_effect_controller.gd` | aplica efeitos temporários dos power-ups |
| `scripts/equations/equation_sequence.gd` | carrega, filtra, embaralha e entrega equações |
| `scripts/settings/difficulty_settings.gd` | centraliza dificuldades, labels e validação |
| `scripts/settings/sound_settings.gd` | normaliza e aplica volume em players de áudio |
| `scripts/screens/settings/settings_screen.gd` | controla o modal de configurações |
| `scripts/hud/hud.gd` | atualiza interface, vidas, score, timer, feedback, pause e game over |
| `scripts/player/record/player_record.gd` | salva e carrega o high score local |
| `scripts/settings/game_settings.gd` | carrega, salva e aplica preferências do usuário |
| `scripts/timer/game_timer.gd` | cronômetro do HUD |

## Observações

- `scripts/hud_old.gd` parece ser uma versão antiga de HUD e não é usada pela cena principal atual.
- Existem assets e cenas auxiliares fora do fluxo principal, como `scenes/scene.tscn`, `power_ups.tscn` e alguns scripts simples de power-ups individuais.
- Os assets `car-kit` e `city-kit-roads` estão incluídos com seus arquivos de licença próprios.
