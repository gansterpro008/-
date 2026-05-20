$wd = New-Object -ComObject Word.Application
$wd.Visible = $false
$doc = $wd.Documents.Add()
$sel = $wd.Selection

$pg = $doc.PageSetup
$pg.LeftMargin = $wd.CentimetersToPoints(2.5)
$pg.RightMargin = $wd.CentimetersToPoints(1.5)
$pg.TopMargin = $wd.CentimetersToPoints(2)
$pg.BottomMargin = $wd.CentimetersToPoints(2)

function SF($s,$b) { $sel.Font.Name='Times New Roman'; $sel.Font.Size=$s; $sel.Font.Bold=$b }
function P($t,$s=14,$b=$false,$al=0,$sb=12,$sa=12,$ls=18,$fi=1.25) {
  SF $s $b
  $sel.ParagraphFormat.Alignment = $al
  $sel.ParagraphFormat.LineSpacingRule = 4
  $sel.ParagraphFormat.LineSpacing = $ls
  $sel.ParagraphFormat.SpaceBefore = $sb
  $sel.ParagraphFormat.SpaceAfter = $sa
  $sel.ParagraphFormat.FirstLineIndent = $wd.CentimetersToPoints($fi)
  $sel.TypeText($t)
  $sel.TypeParagraph()
}
function E { P "" 14 $false 0 0 0 18 0 }
function HC($t) { P $t 14 $true 0 24 18 18 0 }
function HS($t) { P $t 14 $true 0 24 18 18 0 }
function N($t) { P $t 14 $false 0 12 12 18 1.25 }
function BI($t) { P $t 14 $false 0 6 0 18 -1.27 }
function CT($t,$s=14) { P $t $s $false 1 0 0 12 0 }
function CTB($t,$s=14) { P $t $s $true 1 0 0 12 0 }

CT "Министерство образования Новгородской области"
CT "Областное государственное бюджетное"
CT "профессиональное образовательное учреждение"
CT "<Новгородский строительный колледж>"
E
P "Работа допущена к защите" 14 $false 0 0 0 14 0
P "Заместитель директора по УМР" 14 $false 0 0 0 14 0
P "_____________Ю.А. Тюхтина" 14 $false 0 0 0 14 0
P "<_____> ____________ 2024 г." 14 $false 0 0 0 14 0
E
CTB "ДИПЛОМНАЯ РАБОТА" 18
E
CT "на тему <Разработка мобильного приложения"
CT "для учёта товаров на складе>"
E
P "Выполнил:" 14 $false 0 0 0 12 0
P "студент гр. ИСП-04" 14 $false 0 0 0 12 0
E
P "дата" 14 $false 1 0 0 12 0
P "подпись" 14 $false 1 0 0 12 0
E
P "Г.Н. Парфёнов" 14 $false 0 0 0 12 0
E
P "Руководитель:" 14 $false 0 0 0 12 0
P "преподаватель" 14 $false 0 0 0 12 0
E
P "дата" 14 $false 1 0 0 12 0
P "подпись" 14 $false 1 0 0 12 0
E
P "А.Е. Сметанин" 14 $false 0 0 0 12 0
E
P "Нормоконтроль" 14 $false 0 0 0 12 0
P "преподаватель" 14 $false 0 0 0 12 0
E
P "дата" 14 $false 1 0 0 12 0
P "подпись" 14 $false 1 0 0 12 0
E
P "Е.Е. Басова" 14 $false 0 0 0 12 0
E
P "Защита состоялась" 14 $false 0 0 0 12 0
P "<__>_____20___г." 14 $false 0 0 0 12 0
P "Оценка <___________>" 14 $false 0 0 0 12 0
E
CT "Великий Новгород"
CT "2024"

$doc.Words.Last.InsertBreak(7)
