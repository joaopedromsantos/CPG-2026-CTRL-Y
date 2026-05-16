# CPG_CTRL_Y - Math Runner

Jogo 3D feito em Godot no estilo endless runner educativo. O jogador controla um robô em uma pista com três faixas e precisa escolher o bloco com a resposta correta para a equação exibida na tela. A corrida acelera conforme a pontuação aumenta, e o jogador usa power-ups para sobreviver, ganhar mais pontos ou facilitar as respostas.

## Status do Projeto

O projeto já possui um ciclo de jogo funcional:

- tela inicial com seleção de dificuldade;
- jogo principal em 3D;
- geração de equações por dificuldade;
- blocos de resposta nas três pistas;
- pontuação, vidas, cronômetro e feedback visual;
- power-ups coletáveis e ativáveis;
- pausa;
- tela de fim de jogo;
- recorde salvo localmente.

## Requisitos

- Godot 4.6 ou compatível com projeto `config/features=PackedStringArray("4.6", "Forward Plus")`.
- Renderizador Forward Plus.
- Física 3D configurada com Jolt Physics.

## Como Rodar

1. Abra o Godot.
2. Importe a pasta do projeto.
3. Abra o arquivo `project.godot`.
4. Execute o projeto.

A cena inicial configurada é:

```text
res://scenes/start_screen.tscn
```

## Gameplay

O jogo é um runner 3D com três pistas. O personagem corre automaticamente e o jogador muda de faixa para escolher uma das três respostas que aparecem em blocos à frente.

No topo da tela aparece uma equação. Quando uma linha de blocos chega até o jogador, a faixa ocupada pelo personagem define a resposta escolhida.

Se a resposta estiver correta:

- ganha pontos;
- toca som de acerto;
- aparece feedback `Acertou!`;
- uma nova equação é carregada.

Se a resposta estiver errada:

- perde uma vida;
- toca som de erro;
- aparece feedback `Errou!`;
- uma nova equação é carregada.

O jogo termina quando as vidas chegam a zero, exceto se houver um revive ativo disponível.

## Controles

| Ação | Teclas |
| --- | --- |
| Mover para a esquerda | `Seta esquerda` ou `A` |
| Mover para a direita | `Seta direita` ou `D` |
| Pular | `Espaço` |
| Usar power-up do slot 1 | `1` |
| Usar power-up do slot 2 | `2` |
| Usar power-up do slot 3 | `3` |
| Reiniciar após game over | `R` |
| Começar na tela inicial | `Enter` ou botão `COMEÇAR` |
| Pausar/continuar | Botão de pausa no HUD |

## Dificuldades

A tela inicial permite escolher:

- `FACIL`;
- `MEDIO`;
- `DIFICIL`.

Internamente, as dificuldades usadas são:

- `easy`;
- `medium`;
- `hard`.

As perguntas vêm de `data/equations.json`, que contém 200 questões:

- 70 fáceis;
- 70 médias;
- 60 difíceis.

O arquivo suporta questões de resposta única e múltiplas respostas corretas. As opções são embaralhadas antes de entrarem na fila do jogo.

## Sistema de Equações

As equações são carregadas pelo script `scripts/equation_sequence.gd`.

Funcionalidades:

- leitura do arquivo JSON de perguntas;
- validação básica dos campos das questões;
- filtro por dificuldade selecionada;
- embaralhamento das perguntas;
- fila de 3 equações;
- embaralhamento das opções de cada questão.

Cada pergunta usa este formato geral:

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

### Tipos Implementados

| Power-up | Duração | Efeito |
| --- | ---: | --- |
| `lupa` | 6s | destaca visualmente os blocos com resposta correta |
| `revive` | 10s | evita a morte uma vez, restaurando 1 vida quando as vidas chegam a 0 |
| `heart` | 5s | cura 1 vida ao ativar e cura novamente a cada 2s enquanto ativo |
| `lightning` | 5s | resolve automaticamente as linhas como corretas |
| `hourglass` | 6s | reduz a velocidade do mundo para 55% |
| `double` | 8s | dobra a pontuação recebida em acertos |

As configurações ficam em:

```text
assets/power-ups/power_up_config.tres
scripts/power_up_config.gd
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
- botão `COMEÇAR`;
- botões de dificuldade `FACIL`, `MEDIO` e `DIFICIL`;
- início do jogo por botão ou tecla `Enter`.

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

## Recorde Local

O recorde é salvo pelo autoload `PlayerRecord` em:

```text
user://player_record.cfg
```

O valor salvo é o maior número de acertos/pontos alcançado.

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

## Personagem

O jogador usa a cena:

```text
scenes/player.tscn
```

Funcionalidades do personagem:

- movimentação lateral entre três pistas;
- interpolação suave até a pista alvo;
- pulo com gravidade;
- animação de corrida;
- animação de pulo;
- animação de morte;
- som de pulo.

## Cenário

O cenário é gerado por `scripts/cenario.gd`.

Elementos implementados:

- estrada com tiles recicláveis;
- três pistas;
- marcações de pista;
- prédios laterais;
- janelas iluminadas;
- estrelas no fundo;
- câmera 3D;
- luz direcional;
- ambiente com iluminação.

## Estrutura Principal

```text
.
├── assets/
│   ├── car-kit/              # assets 3D de veículos
│   ├── city-kit-roads/       # assets 3D de ruas/cidade
│   ├── fonts/                # fontes e tema
│   ├── hud/                  # ícones e imagens da interface
│   ├── player/               # modelos 3D do jogador
│   ├── power-ups/            # modelos, ícones e configuração de power-ups
│   ├── sounds/               # efeitos sonoros e músicas
│   └── tiles/                # sprites/tilesets adicionais
├── data/
│   └── equations.json        # banco de questões
├── scenes/
│   ├── end_game_screen.tscn
│   ├── hud.tscn
│   ├── main.tscn
│   ├── player.tscn
│   └── start_screen.tscn
├── scripts/
│   ├── blocos.gd
│   ├── cenario.gd
│   ├── equation_sequence.gd
│   ├── game_settings.gd
│   ├── hud.gd
│   ├── main.gd
│   ├── player.gd
│   ├── player_record.gd
│   ├── power-ups.gd
│   ├── power_up_config.gd
│   ├── power_up_effect_controller.gd
│   └── timer.gd
├── project.godot
└── README.md
```

## Scripts Principais

| Arquivo | Função |
| --- | --- |
| `scripts/main.gd` | controla o ciclo principal do jogo, pontuação, vidas, pausa, áudio, game over e conexões entre sistemas |
| `scripts/player.gd` | controla o personagem, pistas, pulo e animações |
| `scripts/blocos.gd` | gera blocos de resposta, resolve a resposta escolhida e emite acerto/erro |
| `scripts/cenario.gd` | cria e atualiza o cenário 3D |
| `scripts/power-ups.gd` | gera power-ups na pista e detecta coleta |
| `scripts/power_up_effect_controller.gd` | aplica efeitos temporários dos power-ups |
| `scripts/equation_sequence.gd` | carrega, filtra, embaralha e entrega equações |
| `scripts/hud.gd` | atualiza interface, vidas, score, timer, feedback, pause e game over |
| `scripts/player_record.gd` | salva e carrega o high score local |
| `scripts/game_settings.gd` | guarda a dificuldade selecionada |
| `scripts/timer.gd` | cronômetro do HUD |

## Autoloads

Configurados em `project.godot`:

```text
PlayerRecord="*res://scripts/player_record.gd"
GameSettings="*res://scripts/game_settings.gd"
```

## Observações do Projeto

- `scripts/hud_old.gd` parece ser uma versão antiga de HUD e não é usada pela cena principal atual.
- Existem assets e cenas auxiliares que não fazem parte direta do fluxo principal atual, como `scenes/scene.tscn`, `power_ups.tscn` e alguns scripts simples de power-ups individuais.
- Os assets `car-kit` e `city-kit-roads` estão incluídos com seus arquivos de licença próprios.
