##############################################################################################################################################################################################################
### Import all Modules before starting deployment or modification

$session = New-CsOnlineSession 
Import-PSSession $session
Import-Module SkypeOnlineConnector

##############################################################################################################################################################################################################
### Set Variables required for CMDlets

$sbcsipport = "5061"
$pstngateway = "teams-sbc.waza.cloud"
$pstnusage = "PSTN Usage for WazaCloud DR"
$onlinevoiceroute = "VoiceRoute-WazaCloud"
$onlinevoiceroutingpolicy = "VoiceRoutingPolicy-WazaCloud"
$numpatt = ".*"
$tenantdialplan = "ZA-WazaCloud"

##############################################################################################################################################################################################################
### List PSTN Gateways, Online Voice Routes and Routing Policies

Get-CSOnlinePSTNGateway
Get-CSOnlineVoiceRoute
Get-CSOnlineVoiceRoutingPolicy

##############################################################################################################################################################################################################
### Pair Office 365 with AudioCodes vSBC

New-CsOnlinePSTNGateway -Fqdn $pstngateway -SipSignallingPort $sbcsipport -ForwardCallHistory $true -ForwardPai $true -MaxConcurrentSessions 10 -Enabled $true

##############################################################################################################################################################################################################
### Create a Tenant Dial Plan, Normalization Rules, Voice Policy, PSTN Usage and Route

$nr1 = New-CsVoiceNormalizationRule -Name 'ZA-TollFree' -Parent Global -Pattern '^0(80\d{7})\d*$' -Translation '+27$1' -InMemory
$nr2 = New-CsVoiceNormalizationRule -Name 'ZA-Premium' -Parent Global -Pattern '^0(86[24-9]\d{6})$' -Translation '+27$1' -InMemory
$nr3 = New-CsVoiceNormalizationRule -Name 'ZA-Mobile' -Parent Global -Pattern '^0((7\d{8}|8[1-5]\d{7}))$' -Translation '+27$1' -InMemory
$nr4 = New-CsVoiceNormalizationRule -Name 'ZA-National' -Parent Global -Pattern '^0(([1-5]\d\d|8[789]\d|86[01])\d{6})\d*(\D+\d+)?$' -Translation '+27$1' -InMemory
$nr5 = New-CsVoiceNormalizationRule -Name 'ZA-Service' -Parent Global -Pattern '^(1\d{2,4})$' -Translation '$1' -InMemory
$nr6 = New-CsVoiceNormalizationRule -Name 'ZA-International' -Parent Global -Pattern '^(?:\+|00)(1|7|2[07]|3[0-46]|39\d|4[013-9]|5[1-8]|6[0-6]|8[1246]|9[0-58]|2[1235689]\d|24[013-9]|242\d|3[578]\d|42\d|5[09]\d|6[789]\d|8[035789]\d|9[679]\d)(?:0)?(\d{6,14})(\D+\d+)?$' -Translation '+$1$2' -InMemory
New-CsTenantDialPlan -Identity $tenantdialplan -NormalizationRules @{Add=$nr1,$nr2,$nr3,$nr4,$nr5,$nr6}

##############################################################################################################################################################################################################
### Create a Voice Route, PSTN Usage and Voice Routing Policy

Set-CsOnlinePstnUsage -Identity Global -Usage @{Add=$pstnusage}
New-CsOnlineVoiceRoute -Identity $onlinevoiceroute -NumberPattern $numpatt -OnlinePstnGatewayList $pstngateway -Priority 1 -OnlinePstnUsages $pstnusage
New-CsOnlineVoiceRoutingPolicy $onlinevoiceroutingpolicy -OnlinePstnUsages $pstnusage

Set-CsOnlinePstnUsage -Identity Global -Usage @{Add=$pstnusage}
Set-CsOnlineVoiceRoute -Identity $onlinevoiceroute -NumberPattern $numpatt -OnlinePstnGatewayList $pstngateway -Priority 1 -OnlinePstnUsages $pstnusage
Set-CsOnlineVoiceRoutingPolicy $onlinevoiceroutingpolicy -OnlinePstnUsages $pstnusage

### WAIT 30 MINUTES BEFORE ASSIGNING A USER TO THE NEW TENANT DIAL PLAN & ROUTING POLICY

For more details: https://docs.microsoft.com/en-us/microsoftteams/direct-routing-configure

##############################################################################################################################################################################################################
### Set Environment Variables

##############################################################################################################################################################################################################
### Import all Modules before starting deployment or modification

$session = New-CsOnlineSession
Import-PSSession $session
Import-Module SkypeOnlineConnector

##############################################################################################################################################################################################################
### Set Variables required for CMDlets

$onlinevoiceroutingpolicy = "VoiceRoutingPolicy-WazaCloud"
$tenantdialplan = "ZA-WazaCloud"

$teamsuser = "warren@waza.cloud"
$e164tel = "+27128802325"

##############################################################################################################################################################################################################
### Verify User is homed Online

Get-CsOnlineUser -Identity $teamsuser | fl RegistrarPool

##############################################################################################################################################################################################################
### Configure User

Set-CsUser -Identity $teamsuser -EnterpriseVoiceEnabled $true -HostedVoiceMail $true -OnPremLineURI tel:$e164tel

##############################################################################################################################################################################################################
### Grant Tenant Dial Plan, Normalization Rules, Voice Policy, PSTN Usage and Route to a Teams User

Grant-CsOnlineVoiceRoutingPolicy -Identity $teamsuser -PolicyName "$onlinevoiceroutingpolicy"
Grant-CsTeamsCallingPolicy -PolicyName AllowCalling -Identity $teamsuser
Grant-CsTenantDialPlan -PolicyName $tenantdialplan -Identity $teamsuser
Grant-CsVoiceRoutingPolicy -Identity $teamsuser -PolicyName InternationalCallsAllowed
Grant-CsTeamsUpgradePolicy -PolicyName UpgradeToTeams -Identity $teamsuser
Grant-CsTeamsMeetingPolicy -PolicyName RestrictedAnonymousAccess -Identity $teamsuser

Get-CsOnlineUser -identity $teamsuser | fl TeamsCallingPolicy,TeamsUpgradeEffectiveMode,TeamsUpgradePolicy,HostedVoiceMail,EnterpriseVoiceEnabled,VoicePolicy,OnlineVoiceRoutingPolicy,LineURI,DialPlan,TenantDialPlan
