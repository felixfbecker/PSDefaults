Import-Module -Force ./PSDefaults.psm1

Describe PSDefaults {

    BeforeEach {
        defaults delete test.domain
        defaults write test.domain TestKey1 -int 123
    }

    Describe Get-DefaultsDomain {
        It 'should return all domains' {
            $domains = Get-DefaultsDomain
            $domains | Should -Contain 'test.domain'
        }
    }

    Describe Get-DefaultsValue {
        It 'should return all defaults values for a domain' {
            $values = Get-DefaultsValue -Domain test.domain
            $values.ContainsKey('TestKey1') | Should -BeTrue
            $values.TestKey1 | Should -BeOfType [bigint]
            $values.TestKey1 | Should -Be 123
        }
        It 'should return the defaults value for a domain and key of type int' {
            $value = Get-DefaultsValue -Domain test.domain -Key TestKey1
            $value | Should -BeOfType [bigint]
            $value | Should -Be 123
        }
        It 'should return the defaults value for a domain and key of type double' {
            defaults write test.domain TestKey2 -float 1.5
            $value = Get-DefaultsValue -Domain test.domain -Key TestKey2
            $value | Should -BeOfType [double]
            $value | Should -Be 1.5
        }
        It 'should return the defaults value for a domain and key of type bool' {
            defaults write test.domain TestKey2 -bool true
            $value = Get-DefaultsValue -Domain test.domain -Key TestKey2
            $value | Should -BeOfType [bool]
            $value | Should -Be $true
        }
        It 'should return the defaults value for a domain and key of type string' {
            defaults write test.domain TestKey2 -string 'abc'
            $value = Get-DefaultsValue -Domain test.domain -Key TestKey2
            $value | Should -BeOfType [string]
            $value | Should -Be 'abc'
        }
        It 'should return the defaults value for a domain and key of type data' {
            defaults write test.domain TestKey2 -data '010203'
            $value = Get-DefaultsValue -Domain test.domain -Key TestKey2
            $value | Should -BeOfType [byte]
            [byte[]]$bytes = 0x01, 0x02, 0x03
            $value | Should -Be $bytes
        }
        It 'should return the defaults value for a domain and key of type date' {
            defaults write test.domain TestDate -date '2019-01-01T00:00:00Z'
            $value = Get-DefaultsValue -Domain test.domain -Key TestDate
            $value | Should -BeOfType [DateTime]
            $value.ToString('o') | Should -Be '2019-01-01T00:00:00.0000000Z'
        }
        It 'should return the defaults value for a domain and key of type array' {
            defaults write test.domain TestKey2 -array -int 1 -int 2
            $value = Get-DefaultsValue -Domain test.domain -Key TestKey2
            $value | Should -BeOfType [bigint]
            $value | Should -Be @(1, 2)
        }
        It 'should return the defaults value for a domain and key of type dict' {
            defaults write test.domain TestKey2 -dict key1 -int 456 key2 -string 'abc'

            $value = Get-DefaultsValue -Domain test.domain -Key TestKey2
            $value | Should -BeOfType [hashtable]

            $value.ContainsKey('key1') | Should -BeTrue
            $value.key1 | Should -BeOfType [bigint]
            $value.key1 | Should -Be 456

            $value.ContainsKey('key2') | Should -BeTrue
            $value.key2 | Should -BeOfType [string]
            $value.key2 | Should -Be 'abc'
        }
    }

    Describe Set-DefaultsValue {
        It 'should set a defaults value for a domain, key and value of type int' {
            Set-DefaultsValue -Domain test.domain -Key TestKey -Value 123
            defaults read-type test.domain TestKey | Should -Be 'Type is integer'
            defaults read test.domain TestKey | Should -Be 123
        }
        It 'should set a defaults value for a domain, key and value of type double' {
            Set-DefaultsValue -Domain test.domain -Key TestFloat -Value 1.5
            defaults read-type test.domain TestFloat | Should -Be 'Type is float'
            defaults read test.domain TestFloat | Should -Be 1.5
        }
        It 'should set a defaults value for a domain, key and value of type bool' {
            Set-DefaultsValue -Domain test.domain -Key TestFloat -Value $true
            defaults read-type test.domain TestFloat | Should -Be 'Type is boolean'
            defaults read test.domain TestFloat | Should -Be '1'
        }
        It 'should set a defaults value for a domain, key and value of type string' {
            Set-DefaultsValue -Domain test.domain -Key TestString -Value 'abc'
            defaults read-type test.domain TestString | Should -Be 'Type is string'
            defaults read test.domain TestString | Should -Be 'abc'
        }
        It 'should set a defaults value for a domain, key and value of type data' {
            [byte[]]$bytes = 0x01, 0x02, 0x03
            Set-DefaultsValue -Domain test.domain -Key TestData -Value $bytes
            defaults read-type test.domain TestData | Should -Be 'Type is data'
            defaults read test.domain TestData | Should -Be '<010203>'
        }
        It 'should set a defaults value for a domain, key and value of type date' {
            Set-DefaultsValue -Domain test.domain -Key TestFloat -Value ([DateTime]::new(2019, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc))
            defaults read-type test.domain TestFloat | Should -Be 'Type is date'
            defaults read test.domain TestFloat | Should -Be '2019-01-01 00:00:00 +0000'
        }
        It 'should set a defaults value for a domain, key and value of type array' {
            Set-DefaultsValue -Domain test.domain -Key TestArray -Value 1, 2, 3
            defaults read-type test.domain TestArray | Should -Be 'Type is array'
            defaults read test.domain TestArray | Should -Be @(
                '(',
                '    1,',
                '    2,',
                '    3',
                ')'
            )
        }
        It 'should set a defaults value for a domain, key and value of type dict' {
            Set-DefaultsValue -Domain test.domain -Key TestDict -Value @{ foo = 'bar' }
            defaults read-type test.domain TestDict | Should -Be 'Type is dictionary'
            defaults read test.domain TestDict | Should -Be @(
                '{',
                '    foo = bar;',
                '}'
            )
        }
        It 'should add a key to a dict a defaults value for a domain, key and value with -Add' {
            defaults write test.domain TestDict -dict foo bar
            Set-DefaultsValue -Domain test.domain -Key TestDict -Value @{ baz = 'qux' } -Add
            defaults read-type test.domain TestDict | Should -Be 'Type is dictionary'
            defaults read test.domain TestDict | Should -Be @(
                '{',
                '    baz = qux;',
                '    foo = bar;',
                '}'
            )
        }
        It 'should add a key to an array defaults value for a domain, key and value with -Add' {
            defaults write test.domain TestArray -array 1 2
            Set-DefaultsValue -Domain test.domain -Key TestArray -Value @(3, 4) -Add
            defaults read-type test.domain TestArray | Should -Be 'Type is array'
            defaults read test.domain TestArray | Should -Be @(
                '(',
                '    1,',
                '    2,',
                '    3,',
                '    4',
                ')'
            )
        }
    }

    Describe Remove-DefaultsValue {
        It 'should remove a defaults value in a domain' {
            Remove-DefaultsValue -Domain test.domain -Key TestKey1
            defaults read test.domain TestKey1
            $LASTEXITCODE | Should -Be 1
        }
    }

    Describe Remove-DefaultsDomain {
        It 'should remove a domain' {
            Remove-DefaultsDomain -Domain test.domain
            defaults read test.domain
            $LASTEXITCODE | Should -Be 1
        }
    }
}
