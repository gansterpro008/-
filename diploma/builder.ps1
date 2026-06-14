$wd = New-Object -ComObject Word.Application; $wd.Visible = $false
$doc = $wd.Documents.Add(); $sel = $wd.Selection
$pg = $doc.PageSetup
$pg.LeftMargin = $wd.CentimetersToPoints(3); $pg.RightMargin = $wd.CentimetersToPoints(1.5)
$pg.TopMargin = $wd.CentimetersToPoints(2); $pg.BottomMargin = $wd.CentimetersToPoints(2)

$lines = [System.IO.File]::ReadAllLines("C:\Users\Shidou\AndroidStudioProjects\uchettovarov\diploma\content.txt", [System.Text.Encoding]::UTF8)
foreach($l in $lines){
  if ($l.Length -eq 0) { continue }
  if ($l.StartsWith("TITLE:")) {$f="Times New Roman";$z=14;$b=0;$a=1;$ls=12;$fi=0;$sb=0;$sa=0}
  elseif ($l.StartsWith("LEFT:")) {$f="Times New Roman";$z=14;$b=0;$a=0;$ls=12;$fi=0;$sb=0;$sa=0}
  elseif ($l.StartsWith("CENTER:")) {$f="Times New Roman";$z=14;$b=0;$a=1;$ls=12;$fi=0;$sb=0;$sa=0}
  elseif ($l.StartsWith("CENTERBIG:")) {$f="Times New Roman";$z=20;$b=1;$a=1;$ls=14;$fi=0;$sb=0;$sa=0}
  elseif ($l -eq "PAGEBREAK") {$doc.Words.Last.InsertBreak(7); continue}
  elseif ($l.StartsWith("P:") -and $l.Length -gt 2) {$f="Times New Roman";$z=14;$b=0;$a=0;$ls=18;$fi=1270;$sb=6;$sa=6}
  elseif ($l.StartsWith("H1:") -and $l.Length -gt 3) {$f="Times New Roman";$z=16;$b=1;$a=0;$ls=18;$fi=0;$sb=24;$sa=12}
  elseif ($l.StartsWith("H2:") -and $l.Length -gt 3) {$f="Times New Roman";$z=15;$b=1;$a=0;$ls=18;$fi=0;$sb=24;$sa=12}
  elseif ($l.StartsWith("EMPTY:")) {for($j=0;$j-lt[int]$l.Substring(6);$j++){$sel.TypeParagraph()}; continue}
  else {continue}
  $sel.Font.Name=$f; $sel.Font.Size=$z; $sel.Font.Bold=$b
  $sel.ParagraphFormat.Alignment=$a; $sel.ParagraphFormat.LineSpacingRule=4
  $sel.ParagraphFormat.LineSpacing=$ls; $sel.ParagraphFormat.FirstLineIndent=$fi
  $sel.ParagraphFormat.SpaceBefore=$sb; $sel.ParagraphFormat.SpaceAfter=$sa
  $t = if ($l.Contains(":")) {$l.Substring($l.IndexOf(":")+1)} else {$l}
  $sel.TypeText($t); $sel.TypeParagraph()
}
$footer = $doc.Sections.Item(1).Footers.Item(1)
$footer.PageNumbers.Add(1) | Out-Null
$footer.Range.Font.Name = "Times New Roman"; $footer.Range.Font.Size = 12
$doc.SaveAs2([ref]"C:\Users\Shidou\AndroidStudioProjects\uchettovarov\diploma\diploma.docx", [ref]16)
$doc.Close(); $wd.Quit()
Write-Output "DONE"
