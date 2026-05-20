$wd = New-Object -ComObject Word.Application; $wd.Visible = $false
$doc = $wd.Documents.Add(); $sel = $wd.Selection
$pg = $doc.PageSetup
$pg.LeftMargin = $wd.CentimetersToPoints(3)
$pg.RightMargin = $wd.CentimetersToPoints(1.5)
$pg.TopMargin = $wd.CentimetersToPoints(2)
$pg.BottomMargin = $wd.CentimetersToPoints(2)

$lines = [System.IO.File]::ReadAllLines("C:\Users\Shidou\AndroidStudioProjects\uchettovarov\diploma\content.txt", [System.Text.Encoding]::UTF8)
foreach($line in $lines){
  if ($line.Length -eq 0) { continue }
  if ($line.StartsWith("TITLE:")) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=14; $sel.Font.Bold=0; $sel.ParagraphFormat.Alignment=1; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=12; $sel.ParagraphFormat.FirstLineIndent=0; $sel.ParagraphFormat.SpaceBefore=0; $sel.ParagraphFormat.SpaceAfter=0; $sel.TypeText($line.Substring(6)); $sel.TypeParagraph() }
  elseif ($line.StartsWith("LEFT:")) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=14; $sel.Font.Bold=0; $sel.ParagraphFormat.Alignment=0; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=12; $sel.ParagraphFormat.FirstLineIndent=0; $sel.ParagraphFormat.SpaceBefore=0; $sel.ParagraphFormat.SpaceAfter=0; $sel.TypeText($line.Substring(5)); $sel.TypeParagraph() }
  elseif ($line.StartsWith("CENTER:")) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=14; $sel.Font.Bold=0; $sel.ParagraphFormat.Alignment=1; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=12; $sel.ParagraphFormat.FirstLineIndent=0; $sel.ParagraphFormat.SpaceBefore=0; $sel.ParagraphFormat.SpaceAfter=0; $sel.TypeText($line.Substring(7)); $sel.TypeParagraph() }
  elseif ($line.StartsWith("CENTERBIG:")) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=20; $sel.Font.Bold=1; $sel.ParagraphFormat.Alignment=1; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=14; $sel.ParagraphFormat.FirstLineIndent=0; $sel.ParagraphFormat.SpaceBefore=0; $sel.ParagraphFormat.SpaceAfter=0; $sel.TypeText($line.Substring(10)); $sel.TypeParagraph() }
  elseif ($line -eq "PAGEBREAK") { $doc.Words.Last.InsertBreak(7) }
  elseif ($line.StartsWith("P:") -and $line.Length -gt 2) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=14; $sel.Font.Bold=0; $sel.ParagraphFormat.Alignment=0; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=18; $sel.ParagraphFormat.FirstLineIndent=1270; $sel.ParagraphFormat.SpaceBefore=6; $sel.ParagraphFormat.SpaceAfter=6; $sel.TypeText($line.Substring(2)); $sel.TypeParagraph() }
  elseif ($line.StartsWith("H1:") -and $line.Length -gt 3) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=16; $sel.Font.Bold=1; $sel.ParagraphFormat.Alignment=0; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=18; $sel.ParagraphFormat.FirstLineIndent=0; $sel.ParagraphFormat.SpaceBefore=24; $sel.ParagraphFormat.SpaceAfter=12; $sel.TypeText($line.Substring(3)); $sel.TypeParagraph() }
  elseif ($line.StartsWith("H2:") -and $line.Length -gt 3) { $sel.Font.Name="Times New Roman"; $sel.Font.Size=15; $sel.Font.Bold=1; $sel.ParagraphFormat.Alignment=0; $sel.ParagraphFormat.LineSpacingRule=4; $sel.ParagraphFormat.LineSpacing=18; $sel.ParagraphFormat.FirstLineIndent=0; $sel.ParagraphFormat.SpaceBefore=24; $sel.ParagraphFormat.SpaceAfter=12; $sel.TypeText($line.Substring(3)); $sel.TypeParagraph() }
  elseif ($line.StartsWith("EMPTY:")) { $c = [int]$line.Substring(6); for($j=0;$j-lt$c;$j++){ $sel.TypeParagraph() } }
}

$footer = $doc.Sections.Item(1).Footers.Item(1)
$footer.PageNumbers.Add(1) | Out-Null
$footer.Range.Font.Name = "Times New Roman"; $footer.Range.Font.Size = 12

$path = "C:\Users\Shidou\AndroidStudioProjects\uchettovarov\diploma\diploma.docx"
$doc.SaveAs2([ref]$path, [ref]16); $doc.Close(); $wd.Quit()
Write-Output "DONE"
