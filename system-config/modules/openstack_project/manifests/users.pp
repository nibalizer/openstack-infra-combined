# == Class: openstack_project::users
#
class openstack_project::users {
  # Make sure we have our UID/GID account minimums for dynamic users set higher
  # than we'll use for static assignments, so as to avoid future conflicts.
  include ::openstack_project::params
  file { '/etc/login.defs':
    ensure => present,
    group  => 'root',
    mode   => '0644',
    owner  => 'root',
    source => $::openstack_project::params::login_defs,
  }
  User::Virtual::Localuser {
    require => File['/etc/login.defs']
  }

  @user::virtual::localuser { 'mordred':
    realname => 'Monty Taylor',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDLsTZJ8hXTmzjKxYh/7V07mIy8xl2HL+9BaUlt6A6TMsL3LSvaVQNSgmXX5g0XfPWSCKmkZb1O28q49jQI2n7n7+sHkxn0dJDxj1N2oNrzNY7pDuPrdtCijczLFdievygXNhXNkQ2WIqHXDquN/jfLLJ9L0jxtxtsUMbiL2xxZEZcaf/K5MqyPhscpqiVNE1MjE4xgPbIbv8gCKtPpYIIrktOMb4JbV7rhOp5DcSP5gXtLhOF5fbBpZ+szqrTVUcBX0oTYr3iRfOje9WPsTZIk9vBfBtF416mCNxMSRc7KhSW727AnUu85hS0xiP0MRAf69KemG1OE1pW+LtDIAEYp',
    key_id   => 'mordred@camelot',
    uid      => 2000,
    gid      => 2000,
  }

  @user::virtual::localuser { 'corvus':
    realname => 'James E. Blair',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAvKYcWK1T7e3PKSFiqb03EYktnoxVASpPoq2rJw2JvhsP0JfS+lKrPzpUQv7L4JCuQMsPNtZ8LnwVEft39k58Kh8XMebSfaqPYAZS5zCNvQUQIhP9myOevBZf4CDeG+gmssqRFcWEwIllfDuIzKBQGVbomR+Y5QuW0HczIbkoOYI6iyf2jB6xg+bmzR2HViofNrSa62CYmHS6dO04Z95J27w6jGWpEOTBjEQvnb9sdBc4EzaBVmxCpa2EilB1u0th7/DvuH0yP4T+X8G8UjW1gZCTOVw06fqlBCST4KjdWw1F/AuOCT7048klbf4H+mCTaEcPzzu3Fkv8ckMWtS/Z9Q==',
    key_id   => 'jeblair@operational-necessity',
    uid      => 2001,
    gid      => 2001,
  }

  @user::virtual::localuser { 'smaffulli':
    realname => 'Stefano Maffulli',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDD/zAvXaOUXCAT6/B4sCMu/38d/PyOIg/tYsYFAMgfDUzuZwkjZWNGrTpp/HFrOAZISER5KmOg48DKPvm91AeZOHfAXHCP6x9/FcogP9rmc48ym1B5XyIc78QVQjgN6JMSlEZsl0GWzFhQsPDjXundflY07TZfSC1IhpG9UgzamEVFcRjmNztnBuvq2uYVGpdI+ghmqFw9kfvSXJvUbj/F7Pco5XyJBx2e+gofe+X/UNee75xgoU/FyE2a6dSSc4uP4oUBvxDNU3gIsUKrSCmV8NuVQvMB8C9gXYR+JqtcvUSS9DdUAA8StP65woVsvuU+lqb+HVAe71JotDfOBd6f',
    key_id   => 'stefano@mattone-E6420',
    uid      => 2002,
    gid      => 2002,
  }

  @user::virtual::localuser { 'oubiwann':
    realname => 'Duncan McGreggor',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAttca0Lahzo1rskWcCGwYh71ADmUsn/6RNBd7H7WVsX+QTacq90fpNghFNTen4I7tC1p0IemwHcCOb1noeXkjxl7W5r7l0OhiqMHp/u2ao0F3dINryuNEww2IHRhY6GwwGJ+slv+i4/FviUgqHZVzopUon/9VY0mu1wfu3vTRw0qXsvqr09Jiavt/8gJ0Fa5PsYkf7l0edFk0scTmGp3G4HY/ZvnbChfZMg6L/xcGPtK/GbLYg6PGtLVVnubXMtxD9GZYhwrY0i9Z2egcRI2W7IznM4OGFzYgA9HZqylPoWt4+ghzC5azUlbO2u6+8HigJVblAGHRWcznEf/ZDR3erw==',
    key_id   => 'oubiwann@rhosgobel',
    uid      => 2003,
    gid      => 2003,
  }

  @user::virtual::localuser { 'rockstar':
    realname => 'Paul Hummer',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDd4dPOAooCImpPulKIH82LqahC2wtQAZS/bFjNRpEILaYQMPCEpSMpjQmhcjdq+OBtsHMbqkSR+ZEoDrkhsI3Y6NVyTlGeFfwCPNNt2VeuJlKqRHUxxecp0IPWGSNl+YI5rjO5hTIZEo9T+hngX2b4k7aPm/naGcBVETMdYDZt9yhX37w5irRFdMfNDdSa3VfrhqV3Jjge/sXA5Tv35s0O6R55Ww5KfZRTpAMesHWkH9ch6xaHgexLNyCtekZQKNRLR5FCk1SYdcV+BJNlmiyjH4Ed+Oy/dFlGWPNARGwNgEWbInROEqXdWvQf+ZAfuwo32umVmmPhFrBxDYrFR1Gp',
    key_id   => 'rockstar@spackrace.local',
    uid      => 2004,
    gid      => 2004,
  }

  @user::virtual::localuser { 'clarkb':
    realname => 'Clark Boylan',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCnfoVhOTkrY7uoebL8PoHXb0Fg4jJqGCbwkxUdNUdheIdbnfyjuRG3iL8WZnzf7nzWnD+IGo6kkAo8BkNMK9L0P0Y+5IjI8NH49KU22tQ1umij4EIf5tzLh4gsqkJmy6QLrlbf10m6UF4rLFQhKzOd4b2H2K6KbP00CIymvbW3BwvNDODM4xRE2uao387qfvXZBUkB0PpRD+7fWPoN58gpFUm407Eba3WwX5PCD+1DD+RVBsG8maIDXerQ7lvFLoSuyMswv1TfkvCj0ZFhSFbfTd2ZysCu6eryFfeixR7NY9SNcp9YTqG6LrxGA7Ci6wz+hycFHXlDrlBgfFJDe5At',
    key_id   => 'clark@work',
    old_keys => [
      'boylandcl@boylancl1',
      ],
    uid      => 2005,
    gid      => 2005,
  }

  @user::virtual::localuser { 'rlane':
    realname => 'Ryan Lane',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCdtI7H+fsgSrjrdG8aGVcrN0GFW3XqLVsLG4n7JW4qH2W//hqgdL7A7cNVQNPoB9I1jAqvnO2Ct6wrVSh84QU89Uufw412M3qNSNeiGgv2c2KdxP2XBrnsLYAaJRbgOWJX7nty1jpO0xwF503ky2W3OMUsCXMAbYmYNSod6gAdzf5Xgo/3+eXRh7NbV1eKPrzwWoMOYh9T0Mvmokon/GXV5PiAA2bIaQvCy4BH/BzWiQwRM7KtiEt5lHahY172aEu+dcWxciuxHqkYqlKhbU+x1fwZJ+MpXSj5KBU+L0yf3iKySob7g6DZDST/Ylcm4MMjpOy8/9Cc6Xgpx77E/Pvd',
    key_id   => 'laner@Free-Public-Wifi.local',
    uid      => 2006,
    gid      => 2006,
  }

  @user::virtual::localuser { 'fungi':
    realname => 'Jeremy Stanley',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQD3KnRBTH5QPpKjf4RWu4akzYt2gwp796cMkFl5vu8e7G/cHuh4979FeNJXMVP6F3rvZB+yXDHLCU5LBVLq0K+1GbAZT/hH38hpMOIvniwKIquvI6C/drkVPHO6YmVlapw/NI530PGnT/TAqCOycHBO5eF1bYsaqV1yZqvs9v7UZc6J4LukoLZwpmyWZ5P3ltAiiy8+FGq3SLCKWDMmv/Bjz4zTsaNbSWThJi0BydINjC1/0ze5Tyc/XgW1sDuxmmXJxgQp4EvLpronqb2hT60iA52kj8lrmoCIryRpgnbaRA7BrxKF8zIr0ZALHijxEUeWHhFJDIVRGUf0Ef0nrmBv',
    key_id   => 'fungi-openstack-2015',
    old_keys => [
      'fungi-openstack-2012',
      'fungi-openstack-2013',
      'fungi-openstack-2014',
      ],
    uid      => 2007,
    gid      => 2007,
  }

  @user::virtual::localuser { 'ttx':
    realname => 'Thierry Carrez',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDCGpMtSehQNZL0/EJ7VUbklJygsxvii2Qi4HPSUFcLJUWAx4VltsmPkmx43D9ITwnRPRMPNtZrOvhY7v0myVlFuRnyTYAqZwigf5gxrktb+4PwCWb+2XobziUVnfJlbOTjneWSTYoZ+OjTaWd5AcVbUvgYAP2qbddycc5ACswpPDo5VrS6fQfCwE4z3BqLFNeOnqxbECHwHeFYIR6Kd6mnKAzDNZxZIkviWg9eIwwuFf5V5bUPiVkeFHVL3EJlCoYs2Em4bvYZBtrV7kUseN85X/+5Uail4uYBEcB3GLL32e6HeD1Qk4xIxLTI2bFPGUp0Oq7iPgrQQe4zCBsGi7Dx+JVy+U0JqLLAN94UPCn2fhsX7PdKfTPcxFPFKeX/PRutkb7qxdbS2ubCdOEhc6WN7OkQmbdK8lk6ms4v4dFc0ooMepWELqKC6thICsVdizpuij0+h8c4SRD3gtwGDPxrkJcodPoAimVVlW1p+RpMxsCFrK473TzgeNPVeAdSZVpqZ865VOwFqoFQB6WpmCDZQPFlkS2VDe9R54ePDHWKYLvVW6yvQqWTx3KrIrS1twSoydj+gADgBYsZaW5MNkWYHAWotEX67j6fMZ6ZSTS5yaTeLywB2Ykh0kjo4jpTFk5JNL7DINkfmCEZMLw60da29iN4QzAJr9cP1bwjf/QDqw==',
    key_id   => 'ttx@mercury',
    uid      => 2008,
    gid      => 2008,
  }

  @user::virtual::localuser { 'rbryant':
    realname => 'Russell Bryant',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDZVikFz5KoRg3gKdiSa3PQ0i2bN5+bUyc4lMMg6P+jEStVddwN+nAgpa3zJaokmNAOp+MjcGa7K1Zi4b9Fe2ufusTzSKdNVlRDiw0R4Lk0LwTIfkhLywKvgcAz8hkqWPUIgTMU4xIizh50KTL9Ttsu9ULop8t7urTpPE4TthHX4nz1Y9NwYLU0W8cWhzgRonBbqtGs/Lif0NC+TdWGkVyTaP3x1A48s0SMPcZKln1hDv7KbKdknG4XyS4jlr4qI+R+har7m2ED/PH93PSXi5QnT4U6laWRg03HTxpPKWq077u/tPW9wcbkgpBcYMmDKTo/NDPtoN+r/jkbdW7zKJHx',
    key_id   => 'russel@russelbryant.net',
    uid      => 2009,
    gid      => 2009,
  }

  @user::virtual::localuser { 'pabelanger':
    realname => 'Paul Belanger',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDIdkI92kJyePsy8MSCgH9VcG5FBdHg+mX8jUniGnxzp2BJ9O+ZVUQLgDIneK/NIoTIs1WIRy5yTuSpqKuX/fZCXdLCfHdHlmNLw5/iF98X9h+c1E5/ZtEuZrfQstP5EHdLxTKD+AEvBSTin9Ptorn+tI1tQf/9hC4flJzOmiFrvhGKhmVd9DToZqMPy2JviajiVu9e/OXdPIcV2hlsm/Db03/zc9Ohkbw6oST/w+ZslvUMCvFUKPAlYG7db4TN+RfWfeWEd3u82beO320zqCPiEHmn2wYAppSXQ+f6beFL6FwejFYgH8F7hEfNyN2Z3V1eR73uSnxfYTGHqgJNAN2Vbl3EmNEhQ60gwuKTXlMpQf5Wny2nJGz7zYCReDbgQH/Zoejw3+Nfk4PcTZtso5Bjti1s+ChGNu3qpS6d7gkEYqcKRtA9If0tP5X5LqUqZw+66BKTBUiXGeip9XCeStN00OdFBcQJZ3h/8xIZsKmkpnBK9uB6NRrFAcxTj9SmpYMUjFOt1nI/b36vCnrcHinSIpWpYAxuySoca5CIJaisQVzG/DzYp801tjCSViKQ0kfMH0cBw0MZOEPYy+itkvDa6chq+gFfmChNJdI4oSqDId8ID60G8eZPDcIKFQAW5kAmdtss11kdwWmszi6KTjdCmbYABfPnt8UGud3WLn5Mew==',
    key_id   => 'pabelanger@redhat.com',
    uid      => 2010,
    gid      => 2010,
  }

  @user::virtual::localuser { 'mkiss':
    realname => 'Marton Kiss',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCb5qdaiKaRqBRgLW8Df+zD3C4a+gO/GFZYEDEd5nvk+LDGPuzi6s639DLqdfx6yvJ1sxxNUOOYhE/T7raDeS8m8fjk0hdVzARXraYDbckt6AELl7B16ZM4aEzjAPoSByizmfwIVkO1zP6kghyumV1kr5Nqx0hTd5/thIzgwdaGBY4I+5iqcWncuLyBCs34oTh/S+QFzjmMgoT86PrdLSsBIINx/4rb2Br2Sb6pRHmzbU+3evnytdlDFwDUPfdzoCaQEdXtjISC0xBdmnjEvHJYgmSkWMZGgRgomrA06Al9M9+2PR7x+burLVVsZf9keRoC7RYLAcryRbGMExC17skL',
    key_id   => 'marton.kiss@gmail.com',
    uid      => 2011,
    gid      => 2011,
  }

  @user::virtual::localuser { 'smarcet':
    realname => 'Sebastian Marcet',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDP5ce0Ywtbgi3LGMZWA5Zlv/EQ07F/gWnZOMN6TRfiCiiBNyf8ARtKgmYSINS8W537HJYBt3qTfa5xkZmpBrtE6x8OTfR5y1L+x/PrLTUkQhVDY19EixD9wDIrQIIjo2ZVq+zErXBRQuGmJ3Hl+OGw+wtvGS8f768kMnwhKUgyITjWV2tKr/q88J8mBOep48XUcRhidDWsOjgIDJQeY2lbsx1bbZ7necrJS17PHqxhUbWntyR/VKKbBbrNmf2bhtTRUSYoJuqabyGDTZ0J25A88Qt2IKELy6jsVTxHj9Y5D8oH57uB7GaNsNiU+CaOcVfwOenES9mcWOr1t5zNOdrp',
    key_id   => 'smarcet@gmail.com',
    uid      => 2012,
    gid      => 2012,
  }

  @user::virtual::localuser { 'zaro':
    realname => 'Khai Do',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDJqB//ilMx7Y1tKzviAn/6yeXSRAi2VnaGN0/bfaa5Gciz+SWt8vAEAUE99fzuqeJ/ezjkuIXDFm/sjZr93y567a6sDT6CuhVUac1FZIhXRTs0J+pBOiENbwQ7RZxbkyNHQ0ndvtz3kBA1DF5D+MDkluBlIWb085Z31rFJmetsB2Zb8s1FKUjHVk/skyeKSj0qAK5KN3Wme6peWhYjwBiM0gUlxIsEZM6JLYdoPIbD5B8GYAktMN2FvJU9LgKGL93jLZ/vnMtoQIHHAG/85NdPURL1Zbi92Xlxbm4LkbcHnruBdmtPfSgaEupwJ+zFmK264OHD7QFt10ztPMbAFCFn',
    key_id   => 'khaido@khaido-HP-EliteBook-Folio-9470m',
    uid      => 2013,
    gid      => 2013,
  }

  @user::virtual::localuser { 'slukjanov':
    realname => 'Sergey Lukjanov',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDHGuIVB/WxBd7k1R8x2FyfqT6KxRnoM7lE5RE8gvBk2r8cQeH5k1c+P5JrBvWpmqXv4satoivYOBiIb7JXEgIxx62YUx/JQ0J7k3w+av6h4iFe2OhOtEOjMF5F8/wO8a/95OeTZPzBZlUfA3hx754kuw3Q/aBKQUOHWxJOIedGyVHeJc7XiFj3RXIufFuUfng9+p4Z3q6d2/WpuKqs00WI0CLF17PkU4i8P9CraJR1dmsWW6zoxMT2G+DwMFI7ZMS3xrVBRuLwrLlbylVLW2kOJ0JeyjHnRh7X1kR7KG3cGOOjA1YQ0e+mXvremcO3/3o6Iop/N1AtqVuYCKlZc7Y9',
    key_id   => 'slukjanov@mirantis.com',
    uid      => 2014,
    gid      => 2014,
  }

  @user::virtual::localuser { 'elizabeth':
    realname => 'Elizabeth K. Joseph',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDL9x1rhTVOEQEanrN+ecycaDtAbbh3kr41Rxx7galtLq0JwftjsZqv2Vwl9c8ARmm8HiHcLwDoaZB9gvs6teMScCB+5a1fcohiycJBl2olNFRzkGapDaTvl74aLXQBWaV84D8tUavEl26zcgwrv9WLUsy9pnHoo5K0BzbK7vT2g3VictCphveC2vdjCDeptocWvt4zxCmAY6O7QMKeUjKMlvuy+zCohJcR4BbDnw8EriFAmCeQZcAgfLTyeAvjo384NNIFWyhCwvbCLvpgTplMCp896DWLlXu9eaGUCNjT/sZM8zafAXbfc6OKYFQ5iANAiJktWwKaUaphJkbSVWT5',
    key_id   => 'elizabeth@r2d2',
    uid      => 2015,
    gid      => 2015,
  }

  @user::virtual::localuser { 'jhesketh':
    realname => 'Joshua Hesketh',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQC3onVLOZiiGpQWTCIV0QwHmc3Jvqyl7UaJxIu7D49OQcLHqVZsozI9pSiCdTnWyAaM+E+5wD9yVcSTqMWqn2AZmZSwQ+Fh6KnCgPZ/o63+iCZPGL0RNk20M1iNh5dvdStDnn+j2fpeV/JONF0tBn07QvNL2eF4BwtbTG9Zhl186QNsXjXDghrSO3Etl6DSfcUhxyvMoA2LnclWWD5hLmiRhcBm+PIxveVsr4B+o0k1HV5SUOvJMWtbEC37AH5I818O4fNOob6CnOFaCsbA9oUDzB5rqxutPZb9SmNJpNoLqYqDgyppM0yeql0Kn97tUt7H4j5xHrWoGnJ4IXfuDc0AMmmy4fpcLGkNf7zcBftKS6iz/3AlOXjlp5WZvKxngJj9HIir2SE/qV4Lxw9936BzvAcQyw5+bEsLQJwi+LPZxEqLC6oklkX9dg/+1yBFHsz6mulA0b4Eq7VF9omRzrhhN4iPpU5KQYPRNz7yRYckXDxYnp2lz6yHgSYh2/lqMc+UqmCL9EAWcDw3jsgvJ6kH/YUVUojiRHD9QLqlhOusu1wrTfojjwF05mqkXKmH+LH8f8AJAlMdYg0c2WLlrcxnwCkLLxzU5cYmKcZ41LuLtQR3ik+EKjYzBXXyCEzFm6qQEbR2akpXyxvONgrf7pijrgNOi0GeatUt0bUQcAONYw==',
    key_id   => 'jhesketh@infra',
    uid      => 2016,
    gid      => 2016,
  }

  @user::virtual::localuser { 'nibz':
    realname => 'Spencer Krum',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDTDia7zLp6NB/DdzhGW/4MDgaQ1yemfF+fGFctrSbBZzP2Aj3RUlBh4Mut3bTIqp/PKNMXVZQbvig5nqF3sB87ZPvmk+7WluFFcQN1RIZnvkYXjF64C+G5PkEZOQW9nqEeElSCV2lXgK98FPrGtK6HgQlYxH5RJa6cufRwYLXLsAwfKRcS3P5oRU2KDORNm6uBfUuX0TyPgtEjYsjCWcffoW+E8kvZbx1DKxF4+u0mWSdkg0P40aAY10mHACtJ4hnu7xNa5Z9Oru1rA1KWL5NHISgy9t5zC1/0jWfYi+tqToBgUCyB8stWgNpHh+QJrpS8CoCDzQLBar0ynnOxBfHH2+s9xJapQNi6ZOC3khWkoxUJn2Gs9FXqow3zGSmEuEKbbUvaGC58U4S0xFcZzF+sOzjRJtw66wE2pQN5Pj/Qw09w6gt05g4nxoxkRVCwMLdnyoIY1oFmywJX3xC1Utu2oCNfgZSn78rqVkE9e11LczPNGvYjl6xQo1r254E0w3QBgo+LaTK5FBRCAbJ76n0IBJ8SZe9foPWjKTGlbCevM6KO8lm58/0m0EfMf9457ZM9KhyXwYvnb+iR7huGC+pwgGemJ4D6vjeE9EUNGSq6igg+v+cl1DHOxVb0s0Tx2T6DMh3usB4C1uoNCR303cmzrNZ94KLXRICQArSClQI7OQ==',
    key_id   => 'nibz@hertz',
    uid      => 2017,
    gid      => 2017,
  }

  @user::virtual::localuser { 'yolanda':
    realname => 'Yolanda Robla',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDSR2NmJC8PSanHUpKJuaMmohG80COO2IPkE3Mxhr7US8P1B3p1c6lOrT6M1txRzBY8FlbxfOinGtutP+ADCB2taXfpO8UiaG9eOqojAT/PeP2Y2ov72rVMSWupLozUv2uAR5yyFVFHOjKPYGAa01aJtfzfJujSak8dM0ifFeFwgp/8RBGEfC7atq+45TdrfAURRcEgcOLiF5Aq6fprCOwpllnrH6VoId9YS7u/5xF2/zBjr9PuOP7jEgCaL/+FNqu7jgj87aG5jiZPlweb7GTLJON9H6eFpyfpoJE0sZ1yR9Q+e9FAqQIA44Zi748qKBlFKbLxzoC4mc0SbNUAleEL',
    key_id   => 'yolanda@infra',
    uid      => 2018,
    gid      => 2018,
  }

  @user::virtual::localuser { 'rcarrillocruz':
    realname => 'Ricardo Carrillo Cruz',
    sshkeys  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDc8rWVoc94ir1fhdC1qK75ZHRXf3JsjrQAx8RZQivICSpZPOpJNCBLJslkKMaSkEIxPOphqgKzp5GusnN5L9/I7DjYuQkqzn4Isi3njym8kWlQR+oDXrB/e/5w0G+WLQKnF9YwvPyw3QXeaUvhAzi/tlj+O3S2ZzWUjA2a12ITG/LFAYVEoSNC4dRJ3eXqIzRiCEkLojC4X2oZfxRv8mxc1vkk1Hpsk3yd2BkqU/v+N76X3CA5OzDDrt/pR8oaQGuncma0G8DuKnRVNmxSgi8HaF9OBwtQ5wnqn7YFQt98T2/cifyC6xhrNkoz9xzDuvxLbMRGAEnG8Tky0cdDSz+x',
    key_id   => 'rcarrillocruz@infra',
    uid      => 2019,
    gid      => 2019,
  }

  @user::virtual::localuser { 'krotscheck':
    realname => 'Michael Krotscheck',
    uid      => 2020,
    gid      => 2020,
  }
}
