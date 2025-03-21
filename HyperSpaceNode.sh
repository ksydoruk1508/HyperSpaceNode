#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

if ! command -v curl &> /dev/null; then
    echo -e "${BLUE}Устанавливаем curl...${NC}"
    sudo apt update
    sudo apt install curl -y
fi

sleep 1

echo -e "${GREEN}"
cat << "EOF"
██   ██ ██    ██ ██████  ███████ ██████  ███████ ██████   █████   ██████ ███████ 
██   ██  ██  ██  ██   ██ ██      ██   ██ ██      ██   ██ ██   ██ ██      ██      
███████   ████   ██████  █████   ██████  ███████ ██████  ███████ ██      █████   
██   ██    ██    ██      ██      ██   ██      ██ ██      ██   ██ ██      ██      
██   ██    ██    ██      ███████ ██   ██ ███████ ██      ██   ██  ██████ ███████ 
                                                                                                                                         
________________________________________________________________________________________________________________________________________


███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                       
                                                                                                                                      
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                             
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                          
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                             
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
echo -e "${NC}"

function download_node {
    echo -e "${BLUE}Начинается установка ноды...${NC}"

    echo -e "${YELLOW}Введите ваш Public key (https://node.hyper.space/): ${NC}"
    read -p "" PRIVATE_KEY
    echo "$PRIVATE_KEY" > $HOME/my.pem

    cd $HOME

    echo -e "${BLUE}Обновляем и устанавливаем необходимые пакеты...${NC}"
    sudo apt-get update -y && sudo apt-get upgrade -y
    sudo apt-get install wget make tar nano libssl-dev build-essential unzip lz4 gcc git jq curl psmisc lsof strace -y

    # Проверка и установка aios-cli
    if ! command -v aios-cli &> /dev/null; then
        echo -e "${BLUE}Устанавливаем aios-cli...${NC}"
        curl -s https://download.hyper.space/api/install | bash
        source ~/.bashrc  # Обновляем PATH после установки
        export PATH=$PATH:$HOME/.aios  # Явно добавляем путь к aios-cli
        sleep 2  # Задержка для обновления PATH
        if ! command -v aios-cli &> /dev/null; then
            echo -e "${RED}Не удалось установить aios-cli. Убедитесь, что система поддерживает установку и интернет-соединение работает.${NC}"
            exit 1
        fi
        echo -e "${GREEN}aios-cli успешно установлен!${NC}"
    fi

    # Очистка всех процессов и файлов aios-cli перед установкой
    echo -e "${BLUE}Очищаем существующие процессы и файлы...${NC}"
    # Принудительно убиваем все процессы aios-cli, включая фоновые и nohup
    pkill -9 -f "aios-cli" 2>/dev/null || echo -e "${YELLOW}Не найдено процессов aios-cli для завершения.${NC}"
    pkill -9 -f "nohup.*aios-cli" 2>/dev/null || echo -e "${YELLOW}Нет процессов nohup для aios-cli.${NC}"
    # Проверка и снятие блокировки файла aios-cli с помощью fuser
    AIOS_CLI_PATH="$HOME/.aios/aios-cli"
    if [ -f "$AIOS_CLI_PATH" ]; then
        if fuser "$AIOS_CLI_PATH" 2>/dev/null | grep -q .; then
            echo -e "${YELLOW}Файл aios-cli заблокирован. Снимаем блокировку...${NC}"
            fuser -k "$AIOS_CLI_PATH" 2>/dev/null || echo -e "${RED}Не удалось снять блокировку файла aios-cli.${NC}"
            sleep 10  # Увеличенная задержка для освобождения файла
        fi
    fi
    # Проверка с lsof (с подавлением ошибок и диагностикой)
    if lsof 2>/dev/null | grep -q aios-cli; then
        PIDS=$(lsof 2>/dev/null | grep aios-cli | awk '{print $2}' | uniq)
        for PID in $PIDS; do
            echo -e "${YELLOW}Найден процесс, блокирующий aios-cli (PID: $PID). Убиваем...${NC}"
            kill -9 $PID 2>/dev/null || echo -e "${RED}Не удалось убить процесс с PID $PID.${NC}"
        done
    else
        echo -e "${YELLOW}Нет заблокированных файлов aios-cli или возникла ошибка lsof.${NC}"
    fi
    # Проверка блокировок на уровне ядра (если доступно)
    if command -v lslocks &> /dev/null; then
        if lslocks | grep -q "$AIOS_CLI_PATH"; then
            echo -e "${YELLOW}Найдена блокировка файла aios-cli на уровне ядра. Пытаемся снять...${NC}"
            fuser -k "$AIOS_CLI_PATH" 2>/dev/null || echo -e "${RED}Не удалось снять блокировку на уровне ядра.${NC}"
            sleep 5
        fi
    fi
    # Дополнительная диагностика с strace
    echo -e "${YELLOW}Проверяем блокировку файла aios-cli с помощью strace...${NC}"
    strace -o $HOME/strace_aios-cli.log aios-cli start 2>&1 >/dev/null || echo -e "${RED}Ошибка при выполнении strace.${NC}"
    if grep -q "Text file busy" $HOME/strace_aios-cli.log; then
        echo -e "${RED}Файл aios-cli заблокирован. Пытаемся устранить проблему...${NC}"
        pkill -9 -f "aios-cli"
        sleep 10
    fi
    # Удаляем директорию, чтобы исключить остатки старых файлов
    sudo rm -rf "$HOME/.aios"

    while true; do
        echo -e "${BLUE}Устанавливаем клиент-скрипт...${NC}"
        curl -s https://download.hyper.space/api/install | bash | tee $HOME/hyperspacenode_install.log

        if ! grep -q "Failed to parse version from release data." $HOME/hyperspacenode_install.log; then
            echo -e "${GREEN}Клиент-скрипт был установлен.${NC}"
            break
        else
            echo -e "${YELLOW}Сервер установки клиента недоступен, повторим через 30 секунд...${NC}"
            sleep 30
        fi
    done

    rm $HOME/hyperspacenode_install.log

    export PATH=$PATH:$HOME/.aios
    source ~/.bashrc

    eval "$(cat ~/.bashrc | tail -n +10)"

    echo -e "${BLUE}Запускаем ноду напрямую (без nohup)...${NC}"
    aios-cli start > $HOME/hyperspacenode.log 2>&1 &

    # Проверка статуса демона
    sleep 20  # Увеличенная задержка для запуска
    if ! pgrep -f "aios-cli start" > /dev/null; then
        echo -e "${RED}Ошибка: Нода (демон aios-cli) не запущена. Проверяйте логи в $HOME/hyperspacenode.log.${NC}"
        echo -e "${YELLOW}Пытаемся диагностировать проблему...${NC}"
        # Логируем состояние для диагностики
        echo "Состояние процессов aios-cli:" > $HOME/hyperspacenode_diagnostic.log
        ps aux | grep aios-cli >> $HOME/hyperspacenode_diagnostic.log 2>/dev/null
        echo "Блокировка файла aios-cli:" >> $HOME/hyperspacenode_diagnostic.log
        lsof 2>/dev/null | grep aios-cli >> $HOME/hyperspacenode_diagnostic.log 2>/dev/null
        echo "Блокировки на уровне ядра:" >> $HOME/hyperspacenode_diagnostic.log
        lslocks 2>/dev/null | grep "$AIOS_CLI_PATH" >> $HOME/hyperspacenode_diagnostic.log 2>/dev/null
        echo "Результат strace:" >> $HOME/hyperspacenode_diagnostic.log
        cat $HOME/strace_aios-cli.log >> $HOME/hyperspacenode_diagnostic.log 2>/dev/null
        # Пытаемся перезапустить вручную с диагностикой
        pkill -9 -f "aios-cli"
        sleep 10
        echo -e "${YELLOW}Пытаемся запустить демон вруч manually...${NC}"
        aios-cli start >> $HOME/hyperspacenode.log 2>&1 &
        sleep 20
        if ! pgrep -f "aios-cli start" > /dev/null; then
            echo -e "${RED}Повторный запуск демона не удался. Проверьте логи в $HOME/hyperspacenode.log и диагностику в $HOME/hyperspacenode_diagnostic.log.${NC}"
            echo -e "${YELLOW}Попробуйте вручную выполнить `aios-cli start` и проверить статус с помощью `aios-cli status` (если доступно).${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}Нода успешно запущена!${NC}"

    # Проверка статуса узла после запуска
    if ! aios-cli status 2>/dev/null | grep -q "running"; then
        echo -e "${YELLOW}Предупреждение: Узел может не быть полностью активен. Проверьте `aios-cli status` и логи.${NC}"
    fi

    while true; do
        echo -e "${BLUE}Устанавливаем модель...${NC}"
        aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee $HOME/hyperspacemodel_download.log

        if grep -q "Download complete" $HOME/hyperspacemodel_download.log; then
            echo -e "${GREEN}Модель была установлена.${NC}"
            break
        elif grep -q "Failed to connect to local daemon" $HOME/hyperspacemodel_download.log; then
            echo -e "${RED}Ошибка: Не удалось подключиться к локальному демону. Проверяйте логи в $HOME/hyperspacenode.log и попробуйте перезапустить ноду.${NC}"
            exit 1
        else
            echo -e "${YELLOW}Сервер установки модели недоступен, повторим через 30 секунд...${NC}"
            sleep 30
        fi
    done

    rm $HOME/hyperspacemodel_download.log

    aios-cli hive import-keys $HOME/my.pem
    aios-cli hive login
    aios-cli hive connect
    echo -e "${GREEN}Нода успешно установлена!${NC}"
    main_menu
}

function check_logs {
    echo -e "${BLUE}Показываем последние 100 строк логов ноды...${NC}"
    if [ -f $HOME/hyperspacenode.log ]; then
        tail -n 100 $HOME/hyperspacenode.log
    else
        echo -e "${RED}Файл логов ноды ($HOME/hyperspacenode.log) не найден.${NC}"
    fi
    echo -e "${BLUE}Просмотр логов завершен. Возвращаемся в главное меню...${NC}"
    main_menu
}

function check_points {
    echo -e "${BLUE}Проверяем количество поинтов...${NC}"
    aios-cli hive points
    echo -e "${BLUE}Проверка завершена.${NC}"
    main_menu
}

function start_points_monitor {
    echo -e "${BLUE}Запускаем автоматическую проверку поинтов...${NC}"

    # Убиваем существующие процессы points_monitor_hyperspace.sh
    PIDS=$(ps aux | grep "[p]oints_monitor_hyperspace.sh" | awk '{print $2}')
    for PID in $PIDS; do
        kill -9 $PID
        echo -e "${GREEN}Процесс с PID $PID завершен${NC}"
    done

    # Создаем скрипт для мониторинга поинтов
    cat > $HOME/points_monitor_hyperspace.sh << 'EOL'
#!/bin/bash
LOG_FILE="$HOME/aios-cli.log"
LAST_POINTS="0"

while true; do
    CURRENT_POINTS=$(aios-cli hive points | grep "Points:" | awk '{print $2}')
    
    if [ "$CURRENT_POINTS" = "$LAST_POINTS" ] || { [ "$CURRENT_POINTS" != "NaN" ] && [ "$LAST_POINTS" != "NaN" ] && [ "$CURRENT_POINTS" -eq "$LAST_POINTS" ]; }; then
        echo "$(date): Поинты не были начислены (Текущее: $CURRENT_POINTS, Предыдущее: $LAST_POINTS), сервис перезапускается..." >> $HOME/points_monitor_hyperspace.log
        
        pkill -f "aios-cli start"
        sleep 5
        nohup bash -c 'aios-cli start' > $HOME/hyperspacenode.log 2>&1 &
    fi
    
    LAST_POINTS="$CURRENT_POINTS"
    
    sleep 10800
done
EOL

    chmod +x $HOME/points_monitor_hyperspace.sh

    # Запускаем скрипт с помощью nohup
    nohup $HOME/points_monitor_hyperspace.sh > $HOME/points_monitor_hyperspace.log 2>&1 &

    echo -e "${GREEN}Автоматическая проверка поинтов запущена в фоновом режиме!${NC}"
    main_menu
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду...${NC}"
    cd $HOME

    # Убиваем процессы points_monitor_hyperspace.sh
    PIDS=$(ps aux | grep "[p]oints_monitor_hyperspace.sh" | awk '{print $2}')
    for PID in $PIDS; do
        kill -9 $PID
        echo -e "${GREEN}Процесс с PID $PID завершен${NC}"
    done

    # Останавливаем и перезапускаем ноду
    pkill -f "aios-cli start"
    sleep 5
    nohup bash -c 'aios-cli start' > $HOME/hyperspacenode.log 2>&1 &

    aios-cli hive import-keys $HOME/my.pem
    aios-cli hive login
    aios-cli hive connect
    echo -e "${GREEN}Нода успешно перезапущена!${NC}"
    main_menu
}

function delete_node {
    echo -e "${YELLOW}Если уверены, что хотите удалить ноду, введите любую букву (CTRL+C чтобы выйти): ${NC}"
    read -p "" checkjust

    echo -e "${BLUE}Начинаю удаление ноды...${NC}"

    # Убиваем процессы points_monitor_hyperspace.sh
    PIDS=$(ps aux | grep "[p]oints_monitor_hyperspace.sh" | awk '{print $2}')
    for PID in $PIDS; do
        kill -9 $PID
        echo -e "${GREEN}Процесс с PID $PID завершен${NC}"
    done

    # Останавливаем ноду
    pkill -f "aios-cli start"
    aios-cli kill
    aios-cli models remove hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
    sudo rm -rf $HOME/.aios
    sudo rm -f $HOME/hyperspacenode.log $HOME/points_monitor_hyperspace.log $HOME/points_monitor_hyperspace.sh $HOME/hyperspacenode_diagnostic.log $HOME/strace_aios-cli.log

    echo -e "${GREEN}Нода была удалена.${NC}"
    main_menu
}

function exit_from_script {
    echo -e "${BLUE}Выход из скрипта...${NC}"
    exit 0
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Просмотр логов${NC}"
        echo -e "${CYAN}3. Узнать сколько поинтов${NC}"
        echo -e "${CYAN}4. Автоматическая проверка поинтов${NC}"
        echo -e "${CYAN}5. Перезапуск ноды${NC}"
        echo -e "${CYAN}6. Удаление ноды${NC}"
        echo -e "${CYAN}7. Выход${NC}"
        
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) download_node ;;
            2) check_logs ;;
            3) check_points ;;
            4) start_points_monitor ;;
            5) restart_node ;;
            6) delete_node ;;
            7) exit_from_script ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
