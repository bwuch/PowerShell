$ruleService = Get-NsxtPolicyService -Name 'com.vmware.nsx_policy.infra.domains.security_policies.rules'
$rule = $ruleService.get('default', 'Test_Policy', 'Test_Rule')
$rule.disabled = $false
$ruleService.patch('default', 'Test_Policy', 'Test_Rule', $rule)
