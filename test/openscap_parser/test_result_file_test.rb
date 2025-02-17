# frozen_string_literal: true

require 'test_helper'

class TestResultFileTest < Minitest::Test
  def setup
    @test_result_file = OpenscapParser::TestResultFile.new(
      file_fixture('xccdf_report.xml').read
    )

    @test_result_file2 = OpenscapParser::TestResultFile.new(
      file_fixture('xccdf_report_with_conflicts_and_requires.xml').read
    )

    @arf_result_file = OpenscapParser::TestResultFile.new(
      file_fixture('arf_report_cs2.xml').read
    )
  end

  context 'benchmark' do
    test 'report_description' do
      assert_match(/^This guide presents/,
                   @test_result_file.benchmark.description)
    end

    test 'be able to parse it' do
      assert_equal 'xccdf_org.ssgproject.content_profile_standard',
                   @test_result_file.benchmark.profiles.first.id
    end

    context 'profiles' do
      test 'profile_id' do
        assert_match(/^xccdf_org.ssgproject.content_profile_C2S/,
                     @test_result_file2.benchmark.profiles.first.id)
      end

      test 'profile_selected_rule_ids' do
        assert_equal(238, @test_result_file2.benchmark.profiles.first.selected_rule_ids.length)
        refute_includes(@test_result_file2.benchmark.profiles.first.selected_rule_ids,
                        'xccdf_org.ssgproject.rules_group_crypto')
        refute_includes(@test_result_file2.benchmark.profiles.first.selected_rule_ids,
                        'xccdf_org.ssgproject.content_group_rule_crypto')
        refute_includes(@test_result_file2.benchmark.profiles.first.selected_rule_ids,
                        'xccdf_org.ssgproject.contentrule_group_crypto')
        refute_includes(@test_result_file2.benchmark.profiles.first.selected_rule_ids,
                        'xccdf_org.ssgproject.content_group_rule_group_crypto')
      end

      test 'profile_unselected_group_ids' do
        assert_equal(186, @test_result_file.benchmark.profiles.first.unselected_group_ids.count)
        assert_includes(@test_result_file.benchmark.profiles.first.unselected_group_ids,
                        'xccdf_org.ssgproject.content_group_mcafee_security_software')
        assert_includes(@test_result_file.benchmark.profiles.first.unselected_group_ids,
                        'xccdf_org.ssgproject.content_group_mcafee_hbss_software')
        assert_includes(@test_result_file.benchmark.profiles.first.unselected_group_ids,
                        'xccdf_org.ssgproject.content_group_certified-vendor')
        assert_includes(@test_result_file.benchmark.profiles.first.unselected_group_ids,
                        'xccdf_org.ssgproject.content_group_restrictions')
      end

      test 'profile_selected_entity_ids' do
        assert_equal(248, @test_result_file2.benchmark.profiles.first.selected_entity_ids.length)
      end

      test 'profile_refined_values' do
        assert_equal({ 'xccdf_org.ssgproject.content_value_var_selinux_state' => 'enforcing',
                       'xccdf_org.ssgproject.content_value_var_selinux_policy_name' => 'targeted',
                       'xccdf_org.ssgproject.content_value_login_banner_text' => 'usgcb_default',
                       'xccdf_org.ssgproject.content_value_var_auditd_max_log_file' => '6',
                       'xccdf_org.ssgproject.content_value_var_auditd_action_mail_acct' => 'root',
                       'xccdf_org.ssgproject.content_value_var_auditd_admin_space_left_action' => 'single',
                       'xccdf_org.ssgproject.content_value_var_sshd_set_keepalive' => '0',
                       'xccdf_org.ssgproject.content_value_var_password_pam_minlen' => '14',
                       'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_unlock_time' => '900',
                       'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_deny' => '5',
                       'xccdf_org.ssgproject.content_value_var_password_pam_unix_remember' => '5',
                       'xccdf_org.ssgproject.content_value_var_accounts_maximum_age_login_defs' => '90',
                       'xccdf_org.ssgproject.content_value_var_accounts_minimum_age_login_defs' => '7',
                       'xccdf_org.ssgproject.content_value_var_accounts_password_warn_age_login_defs' => '7',
                       'xccdf_org.ssgproject.content_value_var_account_disable_post_pw_expiration' => '30' },
                     @test_result_file2.benchmark.profiles.first.refined_values)
      end

      test 'profile_refined_rule_severity' do
        profile = @test_result_file2.benchmark.profiles.find do |p|
          p.id == 'xccdf_org.ssgproject.content_profile_stig_gui'
        end
        assert_equal({ 'xccdf_org.ssgproject.content_rule_sssd_ldap_start_tls' => 'medium',
                       'xccdf_org.ssgproject.content_rule_prefer_64bit_os2' => 'high' },
                     profile.refined_rule_severity)
      end

      test 'profile_refined_rule_role' do
        profile = @test_result_file2.benchmark.profiles.find do |p|
          p.id == 'xccdf_org.ssgproject.content_profile_stig_gui'
        end
        assert_equal({ 'xccdf_org.ssgproject.content_rule_sssd_ldap_start_tls' => 'full',
                       'xccdf_org.ssgproject.content_rule_prefer_64bit_os2' => 'full' },
                     profile.refined_rule_role)
      end

      test 'profile_refined_rule_weight' do
        profile = @test_result_file2.benchmark.profiles.find do |p|
          p.id == 'xccdf_org.ssgproject.content_profile_stig_gui'
        end
        assert_equal({ 'xccdf_org.ssgproject.content_rule_prefer_64bit_os2' => '10' },
                     profile.refined_rule_weight)
      end
    end

    context 'groups' do
      test 'group_id' do
        assert_match(/^xccdf_org.ssgproject.content_group_system/,
                     @test_result_file2.benchmark.groups.first.id)
      end

      test 'group_no_conflicts' do
        assert_equal([], @test_result_file2.benchmark.groups.first.conflicts)
      end

      test 'group_with_conflicts' do
        assert_equal(['xccdf_org.ssgproject.content_rule_selinux_state',
                      'xccdf_org.ssgproject.content_group_mcafee_security_software'],
                     @test_result_file2.benchmark.groups[1].conflicts)
      end

      test 'group_no_requires' do
        assert_equal([], @test_result_file2.benchmark.groups[1].requires)
      end

      test 'group_with_requires' do
        assert_equal(%w[A B C], @test_result_file2.benchmark.groups.first.requires)
      end

      test 'group_description' do
        assert_match(/^Contains rules that check correct system settings./,
                     @test_result_file2.benchmark.groups.first.description)
      end

      test 'group_parent_id_benchmark' do
        assert_match(/^xccdf_org.ssgproject.content_benchmark_RHEL-7/,
                     @test_result_file2.benchmark.groups.first.parent_id)
      end

      test 'group_parent_id_group' do
        assert_match(/^xccdf_org.ssgproject.content_group_system/,
                     @test_result_file2.benchmark.groups[1].parent_id)
      end

      test 'group_parent_type_with_benchmark_parent' do
        assert_match(/^Benchmark/,
                     @test_result_file2.benchmark.groups.first.parent_type)
      end

      test 'group_parent_type_with_group_parent' do
        assert_match(/^Group/,
                     @test_result_file2.benchmark.groups[1].parent_type)
      end
    end

    context 'rules' do
      test 'list all rules' do
        arbitrary_rules = [
          'xccdf_org.ssgproject.content_rule_dir_perms_world_writable_system_owned',
          'xccdf_org.ssgproject.content_rule_bios_enable_execution_restrictions',
          'xccdf_org.ssgproject.content_rule_gconf_gnome_screensaver_lock_enabled',
          'xccdf_org.ssgproject.content_rule_selinux_all_devicefiles_labeled'
        ]

        assert_empty(
          arbitrary_rules - @test_result_file.benchmark.rules.map(&:id)
        )
      end

      test 'removes newlines from rule description' do
        rule = @test_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_service_atd_disabled'
        end

        desc = <<~DESC.gsub("\n", ' ').strip
          The at and batch commands can be used to
          schedule tasks that are meant to be executed only once. This allows delayed
          execution in a manner similar to cron, except that it is not
          recurring. The daemon atd keeps track of tasks scheduled via
          at and batch, and executes them at the specified time.
          The atd service can be disabled with the following command:
          $ sudo systemctl disable atd.service
        DESC

        assert_equal desc, rule.description
      end

      test 'rule_id' do
        assert_match(/^xccdf_org.ssgproject.content_rule_prefer_64bit_os2/,
                     @test_result_file2.benchmark.rules.first.id)
      end
      test 'rule_no_conflicts' do
        assert_equal([], @test_result_file2.benchmark.rules[1].conflicts)
      end
      test 'rule_with_conflicts' do
        assert_equal(['xccdf_org.ssgproject.content_group_system',
                      'xccdf_org.ssgproject.content_rule_selinux_state'],
                     @test_result_file2.benchmark.rules.first.conflicts)
      end
      test 'rule_no_requires' do
        assert_equal([], @test_result_file2.benchmark.rules.first.requires)
      end
      test 'rule_with_requires' do
        assert_equal(['xccdf_org.ssgproject.content_rule_package_audit_installed',
                      'xccdf_org.ssgproject.content_group_integrity',
                      'xccdf_org.ssgproject.content_group_software-integrity'],
                     @test_result_file2.benchmark.rules[1].requires)
      end
      test 'rule_description' do
        assert_match(/^Prefer installation of 64-bit operating systems when the CPU supports it./,
                     @test_result_file2.benchmark.rules[1].description)
      end
      test 'rule_parent_id_benchmark' do
        assert_match(/^xccdf_org.ssgproject.content_benchmark_RHEL-7/,
                     @test_result_file2.benchmark.rules.first.parent_id)
      end
      test 'rule_parent_id_group' do
        assert_match(/^xccdf_org.ssgproject.content_group_software/,
                     @test_result_file2.benchmark.rules[1].parent_id)
      end
      test 'rule_parent_type_with_benchmark_parent' do
        assert_match(/^Benchmark/,
                     @test_result_file2.benchmark.rules.first.parent_type)
      end
      test 'rule_parent_type_with_group_parent' do
        assert_match(/^Group/,
                     @test_result_file2.benchmark.rules[1].parent_type)
      end

      test 'values' do
        rule = @test_result_file2.benchmark.rules.select do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_remember_password_auth'
        end
        assert_equal(['xccdf_org.ssgproject.content_value_var_password_pam_remember_control_flag',
                      'xccdf_org.ssgproject.content_value_var_password_pam_remember'],
                     rule[0].values)
        assert_equal([], @test_result_file2.benchmark.rules[1].values)
      end
    end

    context 'values' do
      test 'value_description' do
        assert_equal('Specify the email address for designated personnel if ' \
          'baseline configurations are changed in an unauthorized manner.',
                     @test_result_file2.benchmark.values.first.description)
      end

      test 'type' do
        assert_equal('string', @test_result_file2.benchmark.values[0].type)
        assert_equal('string', @test_result_file2.benchmark.values[1].type)
        assert_equal('number', @test_result_file2.benchmark.values[4].type)
      end

      test 'lower bound' do
        assert_equal(nil, @test_result_file2.benchmark.values[0].lower_bound)
        assert_equal('0', @test_result_file2.benchmark.values[4].lower_bound)
        assert_equal('1', @test_result_file2.benchmark.values[4].lower_bound('1_day'))
      end

      test 'upper bound' do
        assert_equal(nil, @test_result_file2.benchmark.values[0].upper_bound)
        assert_equal('40000000', @test_result_file2.benchmark.values[4].upper_bound)
        assert_equal('70000000', @test_result_file2.benchmark.values[4].upper_bound('1_day'))
      end

      test 'value' do
        assert_equal('51882M', @test_result_file2.benchmark.values[0].value)
        assert_equal('512M', @test_result_file2.benchmark.values[1].value)
        assert_equal('3h', @test_result_file2.benchmark.values[2].value)
        assert_equal('DEFAULT', @test_result_file2.benchmark.values[3].value)
        assert_equal('212M', @test_result_file2.benchmark.values[0].value('512M'))
        assert_equal('1G', @test_result_file2.benchmark.values[1].value('1G'))
        assert_equal('1h', @test_result_file2.benchmark.values[2].value('1hour'))
        assert_equal('3h', @test_result_file2.benchmark.values[2].value('3hour'))
        assert_equal('DEFAULT2', @test_result_file2.benchmark.values[3].value('default_policy'))
      end
    end

    context 'rule_references' do
      test 'rule references' do
        rule = @test_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_service_atd_disabled'
        end

        references = [
          ['http://iase.disa.mil/stigs/cci/Pages/index.aspx', 'CCI-000381'],
          ['http://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.' \
           '800-53r4.pdf', 'CM-7']
        ]

        assert_equal(references, rule.references.map { |rr| [rr.href, rr.label] })
      end
    end
  end

  context 'test result' do
    test 'report_host' do
      assert_match @test_result_file.test_result.host,
                   'lenovolobato.lobatolan.home'
    end

    test 'score can be parsed' do
      assert_equal(16.220238, @test_result_file.test_result.score)
    end

    context 'profiles' do
      test 'test_result profile_id' do
        assert_equal 'xccdf_org.ssgproject.content_profile_standard',
                     @test_result_file.test_result.profile_id
      end
    end

    context 'rules' do
      test 'should parse rules for xccdf report' do
        parse_rules @test_result_file
      end

      test 'should parse rules for arf report' do
        parse_rules @arf_result_file
      end
    end

    context 'set values' do
      test 'should parse set values for xccdf report' do
        parse_set_values @test_result_file
      end

      test 'should parse set values for arf report' do
        parse_set_values @arf_result_file
      end
    end

    context 'fixes' do
      test 'should parse fixes for xccdf report' do
        parse_fixes @test_result_file
      end

      test 'should parse fixes for arf report' do
        parse_fixes @arf_result_file
      end

      test 'should parse multiple fixes for one rule' do
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_ensure_gpgcheck_globally_activated'
        end
        fixes = rule.fixes
        assert_equal 2, fixes.count
        assert(fixes.map(&:id).all? { |id| id == 'ensure_gpgcheck_globally_activated' })
        refute_equal fixes.first.system, fixes.last.system
      end

      test 'should parse one sub for fix' do
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_ensure_gpgcheck_globally_activated'
        end
        fix = rule.fixes.find { |f| !f.subs.empty? }
        assert_equal 1, fix.subs.count
        assert fix.subs.first.id
        assert fix.subs.first.text
      end

      test 'should parse attributes for fix' do
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_enable_selinux_bootloader'
        end
        fix = rule.fixes.find { |fx| fx.system == 'urn:xccdf:fix:script:sh' }
        assert_empty fix.subs
        assert fix.text
        assert fix.complexity
        assert fix.disruption
        assert fix.strategy
      end

      test 'should parse multiple subs for fix' do
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
        end
        fix = rule.fixes.find { |f| !f.subs.empty? }
        assert_equal 2, fix.subs.count
        sub = fix.subs.last
        assert sub.id
        assert sub.text
        assert sub.use
      end

      test 'should resolve set-values for subs' do
        set_values = @arf_result_file.test_result.set_values
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
        end
        rule.fixes.first.map_child_nodes(set_values).all? { |node| node.is_a? Nokogiri::XML::Text }
      end

      test 'should parse full fix text lines' do
        set_values = @arf_result_file.test_result.set_values
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
        end
        assert_equal 5, rule.fixes.first.full_text_lines(set_values).count
      end

      test 'should compose full fix' do
        set_values = @arf_result_file.test_result.set_values
        rule = @arf_result_file.benchmark.rules.find do |r|
          r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
        end
        assert_equal file_fixture('selinux_full_fix.sh').read, rule.fixes.first.full_text(set_values)
      end
    end
  end

  context 'Verify the parser works the same with ARF and XCCDF files' do
    {
      'xccdf' => OpenscapParser::TestResultFile.new(file_fixture('ssg-rhel9-ds-xccdf.results.xml').read),
      'arf' => OpenscapParser::TestResultFile.new(file_fixture('ssg-rhel9-ds-arf.xml').read)
    }.each do |report_type, report|
      context 'benchmark' do
        test "#{report_type}_report_description" do
          assert_match(/^This guide presents/, report.benchmark.description)
        end

        test "#{report_type}_profile_id" do
          assert_equal 'xccdf_org.ssgproject.content_profile_anssi_bp28_enhanced', report.benchmark.profiles.first.id
        end

        context 'profiles' do
          test "#{report_type}_profile_selected_rule_ids" do
            assert_equal(163, report.benchmark.profiles.first.selected_rule_ids.length)
            refute_includes(report.benchmark.profiles.first.selected_rule_ids,
                            'xccdf_org.ssgproject.rules_group_crypto')
            refute_includes(report.benchmark.profiles.first.selected_rule_ids,
                            'xccdf_org.ssgproject.content_group_rule_crypto')
            refute_includes(report.benchmark.profiles.first.selected_rule_ids,
                            'xccdf_org.ssgproject.contentrule_group_crypto')
            refute_includes(report.benchmark.profiles.first.selected_rule_ids,
                            'xccdf_org.ssgproject.content_group_rule_group_crypto')
          end

          test "#{report_type}_profile_unselected_group_ids" do
            assert_equal(190, report.benchmark.profiles.first.unselected_group_ids.count)
            assert_includes(report.benchmark.profiles.first.unselected_group_ids,
                            'xccdf_org.ssgproject.content_group_accounts-banners')
            assert_includes(report.benchmark.profiles.first.unselected_group_ids,
                            'xccdf_org.ssgproject.content_group_accounts-physical')
            assert_includes(report.benchmark.profiles.first.unselected_group_ids,
                            'xccdf_org.ssgproject.content_group_ftp')
            assert_includes(report.benchmark.profiles.first.unselected_group_ids,
                            'xccdf_org.ssgproject.content_group_gnome_media_settings')
          end

          test "#{report_type}_profile_refined_values" do
            assert_equal(
              {
                'xccdf_org.ssgproject.content_value_var_password_pam_unix_rounds' => '65536',
                'xccdf_org.ssgproject.content_value_var_accounts_maximum_age_login_defs' => '90',
                'xccdf_org.ssgproject.content_value_var_password_pam_minlen' => '18',
                'xccdf_org.ssgproject.content_value_var_password_pam_ocredit' => '1',
                'xccdf_org.ssgproject.content_value_var_password_pam_dcredit' => '1',
                'xccdf_org.ssgproject.content_value_var_password_pam_ucredit' => '1',
                'xccdf_org.ssgproject.content_value_var_password_pam_lcredit' => '1',
                'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_fail_interval' => '900',
                'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_deny' => '3',
                'xccdf_org.ssgproject.content_value_var_password_pam_tally2' => '5',
                'xccdf_org.ssgproject.content_value_var_accounts_passwords_pam_faillock_unlock_time' => '900',
                'xccdf_org.ssgproject.content_value_var_password_pam_remember' => '2',
                'xccdf_org.ssgproject.content_value_var_password_pam_remember_control_flag' => 'requisite',
                'xccdf_org.ssgproject.content_value_var_authselect_profile' => 'sssd',
                'xccdf_org.ssgproject.content_value_var_sudo_umask' => '0027',
                'xccdf_org.ssgproject.content_value_var_sudo_passwd_timeout' => '1_minute',
                'xccdf_org.ssgproject.content_value_var_sudo_dedicated_group' => 'sudogrp',
                'xccdf_org.ssgproject.content_value_var_polyinstantiation_enabled' => 'on',
                'xccdf_org.ssgproject.content_value_sysctl_net_ipv4_conf_all_accept_redirects_value' => 'disabled',
                'xccdf_org.ssgproject.content_value_sysctl_net_ipv4_conf_default_accept_redirects_value' => 'disabled',
                'xccdf_org.ssgproject.content_value_var_selinux_policy_name' => 'targeted',
                'xccdf_org.ssgproject.content_value_var_accounts_user_umask' => '077',
                'xccdf_org.ssgproject.content_value_var_accounts_tmout' => '10_min',
                'xccdf_org.ssgproject.content_value_sshd_idle_timeout_value' => '10_minutes',
                'xccdf_org.ssgproject.content_value_var_selinux_state' => 'enforcing'
              },
              report.benchmark.profiles.first.refined_values
            )
          end
        end

        context 'groups' do
          test "#{report_type}_group_id" do
            assert_match(/^xccdf_org.ssgproject.content_group_system/,
                         report.benchmark.groups.first.id)
          end

          test "#{report_type}_group_no_conflicts" do
            assert_equal([], report.benchmark.groups.first.conflicts)
          end

          test "#{report_type}_group_no_requires" do
            assert_equal([], report.benchmark.groups[1].requires)
          end

          test "#{report_type}_group_description" do
            assert_match(/^Contains rules that check correct system settings./,
                         report.benchmark.groups.first.description)
          end

          test "#{report_type}_group_parent_id_benchmark" do
            assert_match(/^xccdf_org.ssgproject.content_benchmark_RHEL-9/,
                         report.benchmark.groups.first.parent_id)
          end

          test "#{report_type}_group_parent_id_group" do
            assert_match(/^xccdf_org.ssgproject.content_group_system/,
                         report.benchmark.groups[1].parent_id)
          end

          test "#{report_type}_group_parent_type_with_benchmark_parent" do
            assert_match(/^Benchmark/,
                         report.benchmark.groups.first.parent_type)
          end

          test "#{report_type}_group_parent_type_with_group_parent" do
            assert_match(/^Group/,
                         report.benchmark.groups[1].parent_type)
          end
        end

        context 'rules' do
          test "#{report_type}_list all rules" do
            arbitrary_rules = [
              'xccdf_org.ssgproject.content_rule_bios_enable_execution_restrictions',
              'xccdf_org.ssgproject.content_rule_selinux_all_devicefiles_labeled'
            ]
            assert_empty(
              arbitrary_rules - report.benchmark.rules.map(&:id)
            )
          end

          test "#{report_type}_removes newlines from rule description" do
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_service_atd_disabled'
            end

            desc = <<~DESC.gsub("\n", ' ').strip
              The at and batch commands can be used to
              schedule tasks that are meant to be executed only once. This allows delayed
              execution in a manner similar to cron, except that it is not
              recurring. The daemon atd keeps track of tasks scheduled via
              at and batch, and executes them at the specified time.
              The atd service can be disabled with the following command:
              $ sudo systemctl mask --now atd.service
            DESC

            assert_equal desc, rule.description
          end

          test "#{report_type}_rule_id" do
            assert_match(/^xccdf_org.ssgproject.content_rule_prefer_64bit_os/,
                         report.benchmark.rules.first.id)
          end
          test "#{report_type}_rule_no_conflicts" do
            assert_equal([], report.benchmark.rules[1].conflicts)
          end

          test "#{report_type}_rule_no_requires" do
            assert_equal([], report.benchmark.rules.first.requires)
          end

          test "#{report_type}_rule_description" do
            assert_match(/^Without cryptographic integrity protections,/,
                         report.benchmark.rules[1].description)
          end
          test "#{report_type}_rule_parent_id_benchmark" do
            assert_match(/^xccdf_org.ssgproject.content_group_software/,
                         report.benchmark.rules.first.parent_id)
          end
          test "#{report_type}_rule_parent_id_group" do
            assert_match(/^xccdf_org.ssgproject.content_group_rpm_verification/,
                         report.benchmark.rules[1].parent_id)
          end
          test "#{report_type}_rule_parent_type_with_group_parent" do
            assert_match(/^Group/,
                         report.benchmark.rules[1].parent_type)
          end

          test "#{report_type}_values" do
            rule = report.benchmark.rules.select do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_remember_password_auth'
            end
            assert_equal(['xccdf_org.ssgproject.content_value_var_password_pam_remember_control_flag',
                          'xccdf_org.ssgproject.content_value_var_password_pam_remember'],
                         rule[0].values)
            assert_equal([], report.benchmark.rules[1].values)
          end
        end

        context 'test result' do
          test "#{report_type}_report_host" do
            assert_match report.test_result.host, 'vm-rhel9'
          end

          test "#{report_type}_score can be parsed" do
            assert_equal(89.149307, report.test_result.score)
          end

          context 'profiles' do
            test "#{report_type}_test_result profile_id" do
              assert_equal 'xccdf_org.ssgproject.content_profile_anssi_bp28_minimal',
                           report.test_result.profile_id
            end
          end

          context 'rules' do
            test "#{report_type}_should parse rules for #{report_type} report" do
              parse_rules report
            end
          end

          context 'set values' do
            test "#{report_type}_should parse set values for #{report_type} report" do
              parse_set_values report
            end
          end
        end

        context 'fixes' do
          test "#{report_type}_should parse fixes for #{report_type} report" do
            parse_fixes report
          end

          test "#{report_type}_should parse multiple fixes for one rule" do
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_ensure_gpgcheck_globally_activated'
            end
            fixes = rule.fixes
            assert_equal 2, fixes.count
            assert(fixes.map(&:id).all? { |id| id == 'ensure_gpgcheck_globally_activated' })
            refute_equal fixes.first.system, fixes.last.system
          end

          test "#{report_type}_should parse one sub for fix" do
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
            end
            fix = rule.fixes.find { |f| !f.subs.empty? }
            assert_equal 1, fix.subs.count
            assert fix.subs.first.id
            assert fix.subs.first.text
          end

          test "#{report_type}_should parse attributes for fix" do
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_accounts_password_pam_dcredit'
            end
            fix = rule.fixes.find { |fx| fx.system == 'urn:xccdf:fix:script:sh' }
            assert_equal 1, fix.subs.count
            assert fix.text
            assert fix.complexity
            assert fix.disruption
            assert fix.strategy
          end

          test "#{report_type}_should parse multiple subs for fix" do
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_remember_password_auth'
            end
            fix = rule.fixes.find { |f| !f.subs.empty? }
            assert_equal 2, fix.subs.count
            sub = fix.subs.last
            assert sub.id
            assert sub.text
            assert sub.use
          end

          test "#{report_type}_should resolve set-values for subs" do
            set_values = report.test_result.set_values
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
            end
            rule.fixes.first.map_child_nodes(set_values).all? { |node| node.is_a? Nokogiri::XML::Text }
          end

          test "#{report_type}_should parse full fix text lines" do
            set_values = report.test_result.set_values
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
            end
            assert_equal 3, rule.fixes.first.full_text_lines(set_values).count
          end

          test "#{report_type}_should compose full fix" do
            set_values = report.test_result.set_values
            rule = report.benchmark.rules.find do |r|
              r.id == 'xccdf_org.ssgproject.content_rule_selinux_state'
            end
            assert_equal file_fixture('ssh-rehl9-ds-selinux_full_fix.sh').read, rule.fixes.first.full_text(set_values)
          end
        end
      end
    end
  end

  private

  def parse_fixes(result_file)
    fixes = result_file.benchmark.rules.flat_map(&:fixes).map(&:to_h)
    ids = fixes.map { |fix| fix[:id] }
    systems = fixes.map { |fix| fix[:system] }
    refute_empty fixes
    assert_equal ids, ids.compact
    assert_equal systems, systems.compact
  end

  def parse_set_values(result_file)
    set_values = result_file.test_result.set_values.map(&:to_h)
    idrefs = set_values.map { |val| val[:id] }
    texts = set_values.map { |val| val[:text] }
    refute_empty set_values
    assert_equal idrefs, idrefs.compact
    assert_equal texts, texts.compact
  end

  def parse_rules(result_file)
    rules = result_file.benchmark.rules.map(&:to_h)
    ids = rules.map { |rule| rule[:id] }
    titles = rules.map { |rule| rule[:title] }
    selected = rules.map { |rule| rule[:selected] }
    test_parsed_rule_info(rules, ids, titles, selected)
  end

  def test_parsed_rule_info(rules, ids, titles, selected)
    refute_empty rules
    assert_equal ids, ids.compact
    assert_equal titles, titles.compact
    assert_equal selected, selected.compact
  end
end
