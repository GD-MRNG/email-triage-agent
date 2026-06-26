$WEBHOOK_URL = "http://localhost:5678/webhook/email-triage"

Write-Host "--- Testing URGENT ---"
Invoke-RestMethod `
    -Uri $WEBHOOK_URL `
    -Method Post `
    -ContentType "application/json" `
    -InFile "sample-payloads/urgent.json" `
| ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "--- Testing ACTIONABLE ---"
Invoke-RestMethod `
    -Uri $WEBHOOK_URL `
    -Method Post `
    -ContentType "application/json" `
    -InFile "sample-payloads/actionable.json" `
| ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "--- Testing FYI ---"
Invoke-RestMethod `
    -Uri $WEBHOOK_URL `
    -Method Post `
    -ContentType "application/json" `
    -InFile "sample-payloads/fyi.json" `
| ConvertTo-Json -Depth 10