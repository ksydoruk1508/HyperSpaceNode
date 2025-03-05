#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Проверка наличия jq и установка, если не установлен
if ! command -v jq &> /dev/null; then
    sudo apt update
    sudo apt install jq -y
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

function install_node {
    echo -e "${BLUE}Начинаю установку ноды...${NC}"
    aios-cli hive import-keys $HOME/my.pem
    aios-cli hive login
    aios-cli hive connect
    echo -e "${GREEN}Нода успешно установлена!${NC}"
    main_menu
}

function check_logs {
    echo -e "${BLUE}Показываем последние 100 строк логов ноды...${NC}"
    journalctl -u hyperspacenode.service -n 100 | less -FX
    echo -e "${BLUE}Просмотр логов завершен. Возвращаемся в главное меню...${NC}"
    main_menu
}

function check_points {
    echo -e "${BLUE}Проверяем количество поинтов...${NC}"
    aios-cli points
    echo -e "${BLUE}Проверка завершена.${NC}"
    main_menu
}

function start_points_monitor {
    echo -e "${BLUE}Запускаем автоматическую проверку поинтов...${NC}"
    nohup bash -c "while true; do aios-cli points; sleep 300; done" > ~/points_monitor.log 2>&1 &
    echo -e "${GREEN}Автоматическая проверка поинтов запущена в фоновом режиме!${NC}"
    main_menu
}

function restart_node {
    echo -e "${BLUE}Перезапускаем ноду...${NC}"
    aios-cli kill
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

    # Убиваем ноду (убрал screen, так как он не используется)
    aios-cli kill
    aios-cli models remove hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
    sudo rm -rf $HOME/.aios

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
        echo -e "${CYAN}5. Рестарт ноды${NC}"
        echo -e "${CYAN}6. Удаление ноды${NC}"
        echo -e "${CYAN}7. Выход${NC}"
        
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
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
