$wd = New-Object -ComObject Word.Application
$wd.Visible = $false
$doc = $wd.Documents.Add()
$sel = $wd.Selection

$pg = $doc.PageSetup
$pg.LeftMargin = $wd.CentimetersToPoints(3)
$pg.RightMargin = $wd.CentimetersToPoints(1.5)
$pg.TopMargin = $wd.CentimetersToPoints(2)
$pg.BottomMargin = $wd.CentimetersToPoints(2)

function SF($s,$b) { $sel.Font.Name='Times New Roman'; $sel.Font.Size=$s; $sel.Font.Bold=$b }

function P($t,$s=14,$b=$false,$al=0,$in=1.25) {
  SF $s $b
  $sel.ParagraphFormat.Alignment = $al
  $sel.ParagraphFormat.LineSpacingRule = 4
  $sel.ParagraphFormat.LineSpacing = 1.5
  $sel.ParagraphFormat.FirstLineIndent = $wd.CentimetersToPoints($in)
  $sel.TypeText($t)
  $sel.TypeParagraph()
}

function EmptyLine { $sel.TypeParagraph() }
function CenterText($t,$s=14,$b=$false) { P $t $s $b 1 0 }
function NormalText($t,$s=14) { P $t $s $false 0 }

# ===== TITLE PAGE =====
EmptyLine;EmptyLine;EmptyLine
CenterText "Министерство науки и высшего образования Российской Федерации" 14
CenterText "Федеральное государственное бюджетное образовательное учреждение" 14
CenterText "высшего образования" 14
CenterText "[НАЗВАНИЕ ВУЗА]" 14 $true
EmptyLine;EmptyLine
CenterText "Факультет [Факультет]" 14
CenterText "Кафедра [Кафедра]" 14
EmptyLine;EmptyLine;EmptyLine;EmptyLine;EmptyLine
CenterText "ОТЧЕТ ПО УЧЕБНОЙ ПРАКТИКЕ" 16 $true
EmptyLine
CenterText "по специальности 09.02.07" 14
CenterText "Информационные системы и программирование" 14
EmptyLine
CenterText "Тема: Разработка мобильного приложения для учёта товаров на складе" 15 $true
EmptyLine;EmptyLine;EmptyLine;EmptyLine;EmptyLine;EmptyLine
$sel.ParagraphFormat.Alignment = 2
$sel.ParagraphFormat.FirstLineIndent = 0
SF 14 $false
$sel.TypeText("Выполнил: студент гр. ИС-05"); $sel.TypeParagraph()
$sel.TypeText("Иванов И.И."); $sel.TypeParagraph()
EmptyLine
$sel.TypeText("Руководитель:"); $sel.TypeParagraph()
$sel.TypeText("Петров П.П."); $sel.TypeParagraph()
EmptyLine;EmptyLine;EmptyLine;EmptyLine
$sel.ParagraphFormat.Alignment = 1
$sel.ParagraphFormat.FirstLineIndent = 0
$sel.TypeText("[Город], 2026")

$wd.Selection.InsertBreak(7)

# ===== CONTENTS =====
CenterText "СОДЕРЖАНИЕ" 16 $true; EmptyLine
$toc = @("Введение","1. Техническое задание","2. Средства разработки","3. Разработка мобильного приложения на Flutter","  3.1. Создание проекта","  3.2. Разработка интерфейса","  3.3. База данных SQLite","4. Разработка бизнес-логики","  4.1. Приход и расход","  4.2. Статистика","5. Тестирование","6. Сборка","7. Заключение","Список источников")
foreach($i in $toc) { NormalText $i }

$wd.Selection.InsertBreak(7)

# ===== INTRODUCTION =====
CenterText "ВВЕДЕНИЕ" 16 $true; EmptyLine
NormalText "Современный малый и средний бизнес сталкивается с необходимостью автоматизации складского учёта. Большинство существующих решений требуют интернет-подключения или имеют высокую стоимость. Актуальной задачей является разработка доступного мобильного приложения для учёта товаров, работающего автономно."
NormalText "Цель работы: разработка мобильного приложения для учёта товаров на складе с локальным хранением данных на Flutter с использованием SQLite."
NormalText "Задачи:"
NormalText "- создание интерфейса для управления товарами;"
NormalText "- реализация прихода и расхода товаров;"
NormalText "- ведение истории движений по каждому товару;"
NormalText "- статистика по категориям и остаткам;"
NormalText "- работа с контрагентами;"
NormalText "- автономная работа без интернета."

$wd.Selection.InsertBreak(7)

# ===== CHAPTER 1 =====
CenterText "1. ТЕХНИЧЕСКОЕ ЗАДАНИЕ" 16 $true; EmptyLine
NormalText "Разрабатывается приложение со следующим функционалом:"
NormalText "- каталог товаров: название, категория, цена, количество;"
NormalText "- добавление, редактирование, удаление товаров;"
NormalText "- закупка от поставщиков;"
NormalText "- продажа покупателям;"
NormalText "- автоматическое обновление остатков;"
NormalText "- выбор контрагентов из истории;"
NormalText "- фильтрация по категориям и поиск;"
NormalText "- статистика и аналитика;"
NormalText "- светлая и тёмная тема."
NormalText "Технологии: Android, Flutter, Dart, SQLite. Android 5.0+."

$wd.Selection.InsertBreak(7)

# ===== CHAPTER 2 =====
CenterText "2. СРЕДСТВА РАЗРАБОТКИ" 16 $true; EmptyLine
NormalText "Flutter - фреймворк для кроссплатформенной разработки на Dart."
NormalText "Dart - язык с высокой производительностью и строгой типизацией."
NormalText "SQLite - встроенная реляционная БД без отдельного сервера."
NormalText "sqflite - пакет Flutter для работы с SQLite."
NormalText "Среда: Visual Studio Code."

$wd.Selection.InsertBreak(7)

# ===== CHAPTER 3 =====
CenterText "3. РАЗРАБОТКА МОБИЛЬНОГО ПРИЛОЖЕНИЯ НА FLUTTER" 16 $true; EmptyLine
CenterText "3.1. Создание проекта" 15 $true; EmptyLine
NormalText "Структура проекта: models, database, screens, utils. DatabaseHelper-синглтон для работы с БД."
EmptyLine
CenterText "3.2. Разработка интерфейса" 15 $true; EmptyLine
NormalText "Material Design 3. NavigationBar: Товары, Контрагенты, Статистика, Профиль. IndexedStack для сохранения состояния."
NormalText "Товары: карточки с ценой и количеством, поиск, фильтрация чипсами, контекстное меню. Закупка в 3 шага: категория, товар, форма. Продажа с предзаполненной ценой и контролем остатка."
NormalText "Контрагенты: поставщики и покупатели с суммами, детальная история. Статистика: карточки, категории, лента операций. Профиль: организация, пользователь, тема, язык."
NormalText "Предусмотрена поддержка кириллицы."
EmptyLine
CenterText "3.3. База данных SQLite" 15 $true; EmptyLine
NormalText "Таблицы: products, movements, settings. Версия БД 2. Проверка остатка при продаже."

$wd.Selection.InsertBreak(7)

# ===== CHAPTER 4 =====
CenterText "4. РАЗРАБОТКА БИЗНЕС-ЛОГИКИ" 16 $true; EmptyLine
CenterText "4.1. Приход и расход" 15 $true; EmptyLine
NormalText "Закупка: увеличение quantity, запись movements с типом purchase. Продажа: уменьшение quantity с проверкой остатка, запись movements с типом sale. Контрагенты выбираются из bottom sheet с историей."
EmptyLine
CenterText "4.2. Статистика" 15 $true; EmptyLine
NormalText "Агрегирующие SQL-запросы: количество и стоимость товаров, группировка по категориям, суммы по контрагентам, лента 20 операций."

$wd.Selection.InsertBreak(7)

# ===== CHAPTER 5 =====
CenterText "5. ТЕСТИРОВАНИЕ" 16 $true; EmptyLine
NormalText "Тестирование на эмуляторе Pixel 4 API 33 и устройстве Android 13. Проверены: CRUD, закупка/продажа, контроль остатка, поиск и фильтрация, тема, статистика."
NormalText "flutter analyze - 1 предупреждение без влияния на работу."

$wd.Selection.InsertBreak(7)

# ===== CHAPTER 6 =====
CenterText "6. СБОРКА" 16 $true; EmptyLine
NormalText "flutter build apk --release. APK 47 MB. Android 5.0+."

$wd.Selection.InsertBreak(7)

# ===== CONCLUSION =====
CenterText "ЗАКЛЮЧЕНИЕ" 16 $true; EmptyLine
NormalText "Разработано приложение для учёта товаров на Flutter + Dart + SQLite с Material Design 3, поддержкой тем, APK 47 MB."
NormalText "Приложение готово к использованию. Перспективы: резервное копирование, синхронизация, расширенная аналитика."

$wd.Selection.InsertBreak(7)

# ===== REFERENCES =====
CenterText "СПИСОК ИСТОЧНИКОВ" 15 $true; EmptyLine
foreach($r in @("1. Flutter Docs. https://flutter.dev/docs","2. Dart Guide. https://dart.dev/guides","3. sqflite. https://pub.dev/packages/sqflite","4. SQLite. https://www.sqlite.org/docs.html","5. Material Design 3. https://m3.material.io/","6. Flutter API. https://api.flutter.dev/","7. Руководство по оформлению отчётов. Вуз, 2026.")) { NormalText $r }

$path = "C:\Users\Shidou\AndroidStudioProjects\uchettovarov\otchet_praktika.docx"
$doc.SaveAs2([ref]$path, [ref]16)
$doc.Close()
$wd.Quit()
Write-Output "Saved OK"
