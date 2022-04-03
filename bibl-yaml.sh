#!/bin/bash
echo Вас приветствует помощник для ввода библиографии \
	в формате YAML!
echo ""
echo Для выхода завершения работы программы нажмите Ctrl+C.
echo Для отмены текущей книги нажмите Ctrl+D.
echo ""
if [[ $1 == "" ]]; then
	echo Необходимо указать файл, в который будет записываться библиография, например:
	echo "bibl-yaml.sh ~/Библиография.yaml"
	exit 1
elif [[ -d "$1" ]]; then
	echo "$1" является каталогом. Укажите файл, в который будет записываться библиография, например:
	echo "bibl-yaml.sh ~/Библиография.yaml"
	exit 1
elif [[ ! -w "$1" ]]; then
	echo Файл "$1" недоступен для записи.
	echo Укажите другой файл, в который будет записываться библиография, например:
	echo "bibl-yaml.sh ~/Библиография.yaml"
	exit 1
elif [[ -w "$1" ]]; then
	echo Библиография будет записываться в файл "$1".
	echo Текущее содержимое файла будет сохранено.
elif [[ ! -e "$1" ]]; then
	echo Файл "$1" будет создан, библиография будет записываться в него.
	touch "$1"
else
	echo Неизвестная ошибка. "$1" существует, но не является файлом, доступным для записи.
	exit 1
fi
echo ""




#-----------------------------------Вспомогательные функции-------------------------------------
function delete_rows {
	echo -e "\e[$1T"
}
function green {
	echo -n "\e[0;32m$1\e[0m"
}
function red {
	echo -n "\e[0;31m$1\e[0m"
}
function blue {
	echo -n "\e[0;34m$1\e[0m"
}
function increase_rows_to_delete_global {
	rows_to_delete_global=$(($rows_to_delete_global+$1))
}
function print_msg {
	local chars_count=0
	local strs=0
	while [[ $# -gt 0 ]]; do
		echo -en "$1 "
		chars_count=$(($chars_count+$(sed -E 's/\\e\[0(;3[124])?m//g' <<< "$1" | wc -m)+1))
		shift
	done
	echo -e "\b"
	local columns=$(tput cols)
	chars_count=$(($chars_count-1))
	strs=$(($chars_count / $columns))
	if [[ $(($chars_count % $columns)) > 0 ]]; then
		strs=$(($strs+1))
	fi
	return $strs
}
function print_msgs {
	local strs=0
	while [[ $# -gt 0 ]]; do
		print_msg "$1"
		strs=$(($strs+$?))
		shift
	done
	return $strs
}
function read_strs {
	read -r -e -p "$1" $2
	eval str=\$$2
	local chars_count=$((${#1}+${#str}))
	local columns=$(tput cols)
	local strs=$(($chars_count / $columns))
	if [[ $(($chars_count % $columns)) > 0 ]]; then
		strs=$(($strs+1))
	fi
	delete_rows $(($strs+1))
}
function print_persons {
	case $1 in
		автор)
			declare -n persons_list=AUTHORS_LIST
			declare -n persons_strs=authors_strs
			local person_titles=("Автор:" "Авторы:")
			local spaces="       "
			;;
		редактор)
			declare -n persons_list=EDITORS_LIST
			declare -n persons_strs=editors_strs
			local person_titles=("Редактор:" "Редакторы:")
			local spaces="         "
			;;
		составитель)
			declare -n persons_list=COLLECTION_EDITORS_LIST
			declare -n persons_strs=collection_editors_strs
			local person_titles=("Составитель:" "Составители:")
			local spaces="            "
			;;
		переводчик)
			declare -n persons_list=TRANSLATORS_LIST
			declare -n persons_strs=translators_strs
			local person_titles=("Переводчик:" "Переводчики:")
			local spaces="           "
			;;
	esac
	delete_rows $(($persons_strs+1))
	persons_strs=0
	if [[ ${#persons_list[@]} == 1 ]]; then
		print_msg "$(green "${person_titles[0]}")" "${authors[$i]}"
		persons_strs=$((persons_strs+$?))
	else
		local last=$((${#persons_list[@]}-1))
		for (( i=0; i<${#persons_list[@]}; i=i+1 )); do
			if [[ $i == 0 ]]; then
				print_msg "$(green "${person_titles[1]}")" "${persons_list[$i]}"
				persons_strs=$((persons_strs+$?))
			else
				print_msg "$spaces" "${persons_list[$i]}"
				persons_strs=$((persons_strs+$?))
			fi
		done
	fi
	return $persons_strs
}
function normalize_person {
	echo "$1" | sed -r 's/(^| )([а-яА-Я])/\1\U\2/g' | sed -r 's/([а-яА-Я-])([а-яА-Я-]+)/\1\L\2/g'
}
function yes_no {
	print_msgs "$1" \
		"Нажмите на клавишу с буквой, что бы выбрать ответ:" \
		"    [ДY]) да" \
		"    [НN]) нет"
	local strs_select=$?
	rows_to_delete=$(($strs_select+1))
	while true; do
		read -sn1 ans
		case $ans in
			[ДдНнYyNn]) delete_rows $(($rows_to_delete));;&
			[ДдYy]) return 0; break;;
			[НнNn]) return 1; break;;
			*) print_msg "$(red "Ошибка!")" \
				"Введено $ans, ожидается [ДдНнYyNn]."
				rows_to_delete=$((rows_to_delete+$?))
				;;
		esac
	done
}




#-------------------------------Основные функции--------------------------
#---------------------------Выбор типа--------------------------------
function type_select {
print_msgs "Нажмите на клавишу с цифрой, что бы выбрать тип записи:" \
	"    1) книга" \
	"    2) диссертация или автореферат"
strs=$?
rows_to_delete=$(($strs+1))
while true; do
	read -sn1 ans
	case $ans in
		1|2) delete_rows $(($reminder_strs+$rows_to_delete));;&
		1) print_msg "$(green "Выбранный тип:")" книга
			increase_rows_to_delete_global $?
			TYPE=книга
			break;;
		2) print_msg "$(green "Выбранный тип:")" диссертация или автореферат
			increase_rows_to_delete_global $?
			TYPE=диссертация
			break;;
		*) print_msg "$(red "\bОшибка!")" \
			" Введено $ans, ожидается [12]."
			rows_to_delete=$((rows_to_delete+$?))
			;;
	esac
done
}

#---------------------------Выбор метода доступа--------------------------------
function access_method_select {
print_msgs "Нажмите на клавишу с цифрой, что бы метод доступа к тексту:" \
	"    1) непосредственный" \
	"    2) электронный"
strs=$?
rows_to_delete=$(($strs+1))
while true; do
	read -sn1 ans
	case $ans in
		1|2) delete_rows $(($reminder_strs+$rows_to_delete));;&
		1) print_msg "$(green "Выбранный метод доступа:")" непосредственный
			increase_rows_to_delete_global $?
			ACCESS_METHOD=непосредственный
			break;;
		2) print_msg "$(green "Выбранный метод доступа:")" электронный
			increase_rows_to_delete_global $?
			ACCESS_METHOD=электронный
			break;;
		*) print_msg "$(red "\bОшибка!")" \
			" Введено $ans, ожидается [12]."
			rows_to_delete=$((rows_to_delete+$?))
			;;
	esac
done
}

#---------------------------Ввод персон--------------------------------
function persons_input {
case $1 in
	автор) local person_title=автора
		local persons_title="автора(ов)"
		declare -n persons_list=AUTHORS_LIST
		;;
	редактор) local person_title=редактора
		local persons_title="редактора(ов)"
		declare -n persons_list=EDITORS_LIST
		;;
	составитель) local person_title=составителя
		local persons_title="составителя(ей)"
		declare -n persons_list=COLLECTION_EDITORS_LIST
		;;
	переводчик) local person_title=переводчика
		local persons_title="переводчик(ов)"
		declare -n persons_list=TRANSLATORS_LIST
		;;
esac
yes_no "Хотите ли указать $persons_title?" || return 1
print_msgs "Введите $person_title. Варианты ввода:" \
	"* Полное имя, причём фамилия в начале." \
	"* Фамилию и инициалы в любом порядке, причём фамилия в начале или в конце." \
	"Можно ввести несколько персон, разделяя их точками с запятой (\";\")."
strs=$?
error_strs=0
while true; do
	error=0
	read_strs "> " ans
	ans="$(echo "$ans" | sed 's/[.,]/ /g')" # Убрать точки и запятые
	ans=$(echo "$ans" | sed -E 's/\s+/ /g') # схлопнуть пробелы
	IFS=';' read -ra authors <<< "$ans" # разделить по запятыми
	for author in "${authors[@]}"; do # перебор массива авторов
		author="$(echo "$author" | sed 's/^ //' | sed 's/ $//')" #убрать пробелы по краям
		if [[ ! "$author" =~ ^[а-яА-Я\ -]+$ ]]; then
			print_msg "$(red "\bОшибка!")" \
				Персона \""$author"\" не распознана. Разрешённые символы: \
				буквы русского алфавита, точки, запятые, дефисы и пробелы.
			error_strs=$((error_strs+$?))
			error=1
			break
		fi
		if [[ "$author" =~ ^[а-яА-Я-]+$ ]]; then # Если не содержит пробела
			print_msg "$(red "\bОшибка!")" \
				Персона \""$author"\" не распознана. Требуется хотя бы \
				фамилия и один инициал.
			error_strs=$((error_strs+$?))
			error=1
			break
		elif [[ "$author" =~ ^([а-яА-Я-] )+[а-яА-Я-]$ ]]; then # Если только инициалы
			print_msg "$(red "\bОшибка!")" \
				Персона \""$author"\" не распознана. Не найдено фамилии, \
				только инициалы.
			error_strs=$((error_strs+$?))
			error=1
			break
		elif [[ "$author" =~ ^([а-яА-Я-]{2,} )+[а-яА-Я-]{2,}$ ]]; then # Если полное имя
			author="$(normalize_person "$author")"
			persons_list+=("$author")
			print_persons $1
		elif [[ "$author" =~ (^[а-яА-Я-]{2,}\ .*[а-яА-Я-]{2,})|([а-яА-Я-]{2,}.*\ [а-яА-Я-]{2,}$) ]]; then # Если несколько фамилий
			print_msg "$(red "\bОшибка!")" \
				Автор \""$author"\" не распознан. Обнаружено несколько фамилий.
			error_strs=$((error_strs+$?))
			error=1
			break
		elif [[ "$author" =~ ^[а-яА-Я-]{2,} ]]; then # Если фамилия в начале
			author="$(normalize_person "$author")"
			persons_list+=("$author")
			print_persons $1
		elif [[ "$author" =~ [а-яА-Я-]{2,}$  ]]; then # Если фамилия в конце
			author="$(echo "$author" | sed -r 's/^(.*) ([а-яА-Я-]+)$/\2 \1/')" # Перестановка фамилии
			person="$(normalize_person "$author")"
			persons_list+=("$person")
			print_persons $1
		fi
	done
	if yes_no "Хотите ли добавить ещё $persons_title?"; then error=1; else error=0; fi
	delete_rows $((error_strs+1))
	error_strs=0
	if [[ $error == 0 ]]; then break; fi
done
delete_rows $(($strs+1))
print_persons $1
increase_rows_to_delete_global $?
}
function field_input {
	case $1 in
	заглавие) local name="основное заглавие"
		local msg="основной заголовок"
		declare -n title=TITLE
		;;
	вид) local name="вид издания"
		local msg="$(blue "учеб. пособие"), $(blue "офиц. текст"), $(blue "сб. трудов") и др."
		declare -n title=COLLECTION_TITLE
		;;
	издание) local name="сведения об издании"
		local msg="$(blue "2-е изд. перераб. и доп."), $(blue "Новая версия")."
		declare -n title=EDITION
		;;
	издатель) local name="издатель"
		local msg="$(blue "Лань"), $(blue "Планета музыки")."
		declare -n title=PUBLISHER
		;;
	место) local name="место издания"
		local msg="$(blue "М."), $(blue "СПб. [и др.]"), $(blue "В Санктпитербурхе")."
		declare -n title=PUBLISHER_PLACE
		;;
	год) local name="год издания"
		local msg="$(blue "2013")."
		declare -n title=ISSUED
		;;
	страницы) local name="число страниц"
		local msg="$(blue "396")."
		declare -n title=NUMBER_OF_PAGES
		;;
	isbn) local name="международный идентификационный номер"
		local msg="ISBN, например $(blue "978-5-8114-1612-71")."
		declare -n title=ISBN
		;;
	id) local name="id"
		local msg="для ссылок из текста, например $(blue "морозовИРП"); не используйте пробелы."
		declare -n title=ID
		;;
	тип) local name="тип диссертации или автореферата"
		local msg="например $(blue "дис. канд. тех. наук : 05.13.06")."
		declare -n title=GENRE
		;;
	esac
	local name_capital="$(echo $name | sed -E 's/^([а-яa-z])/\U\1/')"
	print_msgs "Введите $name ($msg)" "Если вы не хотите вводить $name, просто нажмите <ENTER>."
	local strs=$?
	read_strs "> " ans
	delete_rows $(($strs+1))
	[[ $ans ]] || return 1
	ans="$(echo "$ans" | sed -E 's/\s+/ /g')" # схлопнуть пробелы
	ans="$(echo "$ans" | sed -E 's/^ //' | sed -E 's/ $//')" # убрать пробелы с краёв
	if [[ "$1" == "isbn" || "$1" == "год" ]]; then # Если цифры, заменить чёрточки
		ans="$(echo "$ans" | sed -E 's/-/‒/g')"
	fi
	title="$ans"
	print_msg "$(green "$name_capital:")" "$title"
	increase_rows_to_delete_global $?
}
function persons_output {
	eval persons_list_name=$1S_LIST
	local count=$(eval "echo \${#$persons_list_name[@]}")
	if [[ $count == 0 ]]; then return 1; fi
	echo "  $(echo $1 | sed -E 's/^(.*)$/\L\1/'):" >&3
	for (( i=0; i<$count; i=i+1 )); do
		eval "person=\"\${$persons_list_name[$i]}\""
		echo "  - family: ${person%% *}" >&3
		echo "    given: ${person#* }" >&3
	done
}
function field_output {
	eval field_name=\$$1
	if [[ $field_name == "" ]]; then return 1; fi
	echo "  $(echo $1 | sed -E 's/^(.*)$/\L\1/' | sed -E 's/_/-/g'): '$field_name'" >&3
}




#-------------------------------Основной блок-----------------------------------
while true; do
	type_select
	field_input заглавие
	persons_input автор
	if [[ $TYPE == книга ]]; then
		persons_input редактор
		#persons_input составитель
		persons_input переводчик
		field_input вид
		field_input издание
	elif [[ $TYPE == диссертация ]]; then
		field_input тип
	fi
	field_input издатель
	field_input место
	field_input год
	field_input страницы
	if [[ $TYPE == книга ]]; then field_input isbn; fi
	field_input id
	[[ $ID ]] || ID=$(mktemp -u | sed 's|^/tmp/tmp\.||') #Если ID пустое, назначить случайный ID
	access_method_select

	sed -i '/^\.\.\.\s*/d' $1
	exec 3>>$1
	echo "- id: $ID" >&3
	case $TYPE in
		книга) echo "  type: book" >&3;;
		диссертация) echo "  type: thesis" >&3;;
	esac
	persons_output AUTHOR
	persons_output EDITOR
	persons_output COLLECTION_EDITOR
	persons_output TRANSLATOR
	field_output TITLE
	field_output COLLECTION_TITLE
	field_output GENRE
	field_output EDITION
	echo "  issued:" >&3
	echo "  - year: $ISSUED" >&3
	field_output NUMBER_OF_PAGES
	field_output PUBLISHER
	field_output PUBLISHER_PLACE
	field_output ISBN
	echo "  content-type: Текст" >&3
	echo "  access-method: $ACCESS_METHOD" >&3
	echo "..." >&3
	exec 3>&-
	
	unset ID
	unset TYPE
	unset AUTHORS_LIST
	unset EDITORS_LIST
	unset COLLECTION_EDITORS_LIST
	unset TRANSLATORS_LIST
	unset EDITION
	unset ISSUED
	unset PUBLISHER
	unset PUBLISHER_PLACE
	unset ISBN
	unset GENRE
	unset TITLE
	unset ACCESS_METHOD
	delete_rows $(($rows_to_delete_global+1))
	rows_to_delete_global=0
	print_msgs "$(green "Библиографическая запись сохранена в файл!")" "Введите следующую запись." ""
	reminder_strs=$?
done
