Add-Type -AssemblyName System.Drawing
$ppt = New-Object -ComObject PowerPoint.Application
$p = $ppt.Presentations.Add()

# Color scheme
$bgColor = [System.Drawing.Color]::FromArgb(255, 25, 35, 55)
$accentColor = [System.Drawing.Color]::FromArgb(255, 63, 130, 220)
$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$lightGray = [System.Drawing.Color]::FromArgb(255, 200, 210, 225)

function Add-Bg($s) {
  $rect = $s.Shapes.AddShape(1, 0, 0, 960, 540)
  $rect.Fill.ForeColor.RGB = $bgColor
  $rect.Fill.Visible = -1
  $rect.Line.Visible = $false
}

function Add-AccentLine($s, $top) {
  $line = $s.Shapes.AddShape(1, 40, $top, 880, 4)
  $line.Fill.ForeColor.RGB = $accentColor
  $line.Fill.Visible = -1
  $line.Line.Visible = $false
}

function Add-Title($s, $txt) {
  $tb = $s.Shapes.AddTextbox(1, 40, 25, 880, 55)
  $tb.TextFrame.TextRange.Text = $txt
  $tb.TextFrame.TextRange.Font.Size = 28
  $tb.TextFrame.TextRange.Font.Bold = -1
  $tb.TextFrame.TextRange.Font.Color.RGB = $white
  Add-AccentLine $s 80
}

function Add-Text($s, $l, $t, $w, $h, $txt, $sz=16, $b=$false, $c=$null) {
  if ($c -eq $null) { $c = $lightGray }
  $tb = $s.Shapes.AddTextbox(1, $l, $t, $w, $h)
  $tb.TextFrame.TextRange.Text = $txt
  $tb.TextFrame.TextRange.Font.Size = $sz
  $tb.TextFrame.TextRange.Font.Bold = $b
  $tb.TextFrame.TextRange.Font.Color.RGB = $c
  return $tb
}

function Add-Bullet($s, $l, $t, $w, $h, $txt, $sz=15) {
  $tb = Add-Text $s ($l+15) $t $w $h $txt $sz
  # Add bullet circle
  $dot = $s.Shapes.AddShape(9, $l, $t+7, 8, 8)
  $dot.Fill.ForeColor.RGB = $accentColor
  $dot.Fill.Visible = -1
  $dot.Line.Visible = $false
}

# === SLIDE 1: Title ===
$s1 = $p.Slides.Add(1, 1)
Add-Bg $s1
$tb = Add-Text $s1 60 160 840 80 "Мобильное приложение для учёта товаров на складе" 32 $true $white
$line = $s1.Shapes.AddShape(1, 60, 250, 200, 3)
$line.Fill.ForeColor.RGB = $accentColor; $line.Fill.Visible = -1; $line.Line.Visible = $false
Add-Text $s1 60 270 840 40 "Учебная практика • 2026 год" 20 $false $lightGray
Add-Text $s1 60 310 840 30 "Flutter • SQLite • Android" 16

# === SLIDE 2: Goals ===
$s2 = $p.Slides.Add(2, 2)
Add-Bg $s2; Add-Title $s2 "Цель и задачи"
Add-Text $s2 50 100 860 45 "Цель: Разработать мобильное приложение для учёта товаров на складе с локальным хранением данных" 16 $true $white
Add-Text $s2 50 155 860 25 "Задачи:" 17 $true $white
$tasks = @("Создание интуитивного интерфейса для управления товарами", "Реализация операций прихода и расхода товаров", "Ведение истории движений по каждому товару", "Статистика по категориям и остаткам на складе", "Работа с контрагентами (поставщики и покупатели)", "Автономная работа без подключения к интернету")
$y = 190
foreach($t in $tasks) { Add-Bullet $s2 60 $y 850 25 $t 15; $y += 32 }

# === SLIDE 3: Relevance ===
$s3 = $p.Slides.Add(3, 2)
Add-Bg $s3; Add-Title $s3 "Актуальность"
Add-Text $s3 50 100 860 50 "Малый и средний бизнес часто не имеет доступа к дорогим облачным ERP-системам. Большинство существующих решений требуют постоянного интернет-подключения и ежемесячной оплаты." 15
$rels = @("Полностью бесплатное решение с открытым исходным кодом", "Работает без интернета — все данные на устройстве", "Простой и понятный интерфейс на русском языке", "Не требует покупки серверного оборудования", "Подходит для ИП, небольших магазинов и складов", "Мгновенный запуск — установил и пользуешься")
$y = 165
foreach($r in $rels) { Add-Bullet $s3 60 $y 850 25 $r 15; $y += 30 }

# === SLIDE 4: DB Choice ===
$s4 = $p.Slides.Add(4, 2)
Add-Bg $s4; Add-Title $s4 "Выбор базы данных"
Add-Text $s4 50 100 860 30 "SQLite — встроенная реляционная база данных" 20 $true $white

$features = @("Не требует установки отдельного сервера — работает «из коробки»", "Хранится в одном файле .db на устройстве пользователя", "Поддерживает стандартные SQL-запросы (SELECT, INSERT, UPDATE)", "Минимальное потребление оперативной памяти", "Встроенная поддержка в Flutter через пакет sqflite", "Транзакции и внешние ключи для целостности данных", "Мгновенный доступ без интернет-соединения")
$y = 145
foreach($f in $features) { Add-Bullet $s4 60 $y 850 22 $f 14; $y += 27 }

# Block with итог
$block = $s4.Shapes.AddShape(1, 50, 370, 860, 55)
$block.Fill.ForeColor.RGB = $accentColor; $block.Fill.Visible = -1; $block.Line.Visible = $false
$block.TextFrame.TextRange.Text = "Итог: SQLite — оптимальный выбор для локального мобильного приложения"
$block.TextFrame.TextRange.Font.Size = 18; $block.TextFrame.TextRange.Font.Bold = -1
$block.TextFrame.TextRange.Font.Color.RGB = $white
$block.TextFrame.TextRange.ParagraphFormat.Alignment = 1

# === SLIDE 5-8: Demo ===
$demos = @(
  @("Главный экран и каталог товаров", "• Список всех товаров с количеством и ценой в рублях", "• Поиск по названию или категории товара", "• Фильтрация по категориям (удобные чипсы)", "• Быстрые действия: закупка, продажа, редактирование", "• Добавление и удаление категорий долгим нажатием", "• Тёмная и светлая тема оформления"),
  @("Закупка и продажа товаров", "• Закупка: выбор категории → выбор товара → форма", "• Продажа: выбор товара → количество, цена, покупатель", "• Автоматическая подстановка цены товара при продаже", "• Выбор контрагента из прошлых поставок", "• Добавление нового поставщика/покупателя", "• Проверка остатка — нельзя продать больше, чем есть"),
  @("Контрагенты и статистика", "• Список поставщиков с суммой и количеством закупок", "• Список покупателей с историей продаж", "• Детальная информация по каждому контрагенту", "• Общая статистика: количество товаров, остатки, стоимость", "• Статистика по категориям с суммой в рублях", "• Лента последних операций с датами и суммами"),
  @("История, профиль и настройки", "• История движений по каждому товару с датами", "• Отображение прихода и расхода в деталях товара", "• Профиль организации (название, адрес, телефон)", "• Профиль пользователя (имя, должность)", "• Смена темы: светлая / тёмная", "• Язык интерфейса: русский / английский")
)

for ($i = 0; $i -lt 4; $i++) {
  $s = $p.Slides.Add(5 + $i, 2)
  Add-Bg $s; Add-Title $s ("Демонстрация " + ($i+1) + " — " + $demos[$i][0])
  $y = 105
  for ($j = 1; $j -lt $demos[$i].Length; $j++) {
    Add-Bullet $s 55 $y 870 22 $demos[$i][$j] 14
    $y += 28
  }
  # Number circle bottom-right
  $num = $s.Shapes.AddShape(9, 870, 475, 40, 40)
  $num.Fill.ForeColor.RGB = $accentColor; $num.Fill.Visible = -1; $num.Line.Visible = $false
  $num.TextFrame.TextRange.Text = ($i+1).ToString()
  $num.TextFrame.TextRange.Font.Size = 18; $num.TextFrame.TextRange.Font.Bold = -1
  $num.TextFrame.TextRange.Font.Color.RGB = $white
  $num.TextFrame.TextRange.ParagraphFormat.Alignment = 1
}

# === SLIDE 9: Conclusion ===
$s9 = $p.Slides.Add(9, 2)
Add-Bg $s9; Add-Title $s9 "Заключение"
Add-Text $s9 50 100 860 40 "Разработано полнофункциональное мобильное приложение для учёта товаров на складе:" 17
$conc = @("Платформа: Flutter (язык Dart) — кроссплатформенная разработка", "База данных: SQLite — локальное хранение без доступа в интернет", "Функции: каталог, закупка, продажа, контрагенты, аналитика", "Интерфейс: Material Design 3, светлая/тёмная тема, русский язык", "Размер APK: 47 МБ, поддержка Android 5.0 и выше")
$y = 150
foreach($c in $conc) { Add-Bullet $s9 60 $y 850 25 $c; $y += 33 }

$block2 = $s9.Shapes.AddShape(1, 50, 350, 860, 55)
$block2.Fill.ForeColor.RGB = $accentColor; $block2.Fill.Visible = -1; $block2.Line.Visible = $false
$block2.TextFrame.TextRange.Text = "Приложение готово к использованию и может быть доработано под конкретные задачи бизнеса"
$block2.TextFrame.TextRange.Font.Size = 16; $block2.TextFrame.TextRange.Font.Bold = -1
$block2.TextFrame.TextRange.Font.Color.RGB = $white
$block2.TextFrame.TextRange.ParagraphFormat.Alignment = 1

Add-Text $s9 50 430 860 25 "Спасибо за внимание!" 22 $true $white

$path = Join-Path $pwd.Path "prezentatsiya.pptx"
$p.SaveAs($path)
$p.Close()
$ppt.Quit()
Write-Output "Saved: $path"
