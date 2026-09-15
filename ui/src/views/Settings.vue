<!--
  Copyright (C) 2026 tebbi
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title"><h2>{{ $t("settings.title") }}</h2></cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification kind="error" :title="$t('action.get-configuration')" :description="error.getConfiguration" :showCloseButton="false" />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <!-- Live state -->
          <NsInlineNotification
            v-if="!loading.getConfiguration"
            :kind="app_up ? 'success' : (container_running ? 'warning' : 'info')"
            :title="statusTitle"
            :description="url ? $t('settings.web_url_desc', { url }) : ''"
            :showCloseButton="false"
            class="info-tile"
          />
          <div v-if="!loading.getConfiguration && url" class="connect">
            <a :href="url" target="_blank" rel="noopener">{{ $t("settings.web_url") }}: {{ url }}</a>
          </div>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input :label="$t('settings.host')" v-model.trim="host" :placeholder="$t('settings.host_placeholder')" :helper-text="$t('settings.host_helper')" :disabled="busy" :invalid-message="$t(error.host)" ref="host" class="field"></cv-text-input>
            <cv-toggle value="letsEncrypt" :label="$t('settings.lets_encrypt')" v-model="lets_encrypt" :disabled="busy" class="toggle">
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <cv-toggle value="http2https" :label="$t('settings.http2https')" v-model="http2https" :disabled="busy" class="toggle">
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <cv-text-input type="password" :label="$t('settings.password')" v-model.trim="password" :placeholder="password_set ? $t('settings.password_placeholder') : ''" :helper-text="$t('settings.password_helper')" :password-hide-label="$t('settings.hide')" :password-show-label="$t('settings.show')" :disabled="busy" :invalid-message="$t(error.password)" ref="password" class="field"></cv-text-input>
            <div class="bx--form__helper-text">{{ password_set ? $t("settings.password_set") : $t("settings.password_not_set") }}</div>

            <!-- AiiDA identity -->
            <h4 class="section">{{ $t("settings.identity_section") }}</h4>
            <div class="bx--form__helper-text">{{ $t("settings.identity_helper") }}</div>
            <cv-text-input :label="$t('settings.aiida_user_email')" v-model.trim="aiida_user_email" :disabled="busy" :invalid-message="$t(error.aiida_user_email)" ref="aiida_user_email" class="field"></cv-text-input>
            <cv-text-input :label="$t('settings.aiida_user_first_name')" v-model.trim="aiida_user_first_name" :disabled="busy" :invalid-message="$t(error.aiida_user_first_name)" class="field"></cv-text-input>
            <cv-text-input :label="$t('settings.aiida_user_last_name')" v-model.trim="aiida_user_last_name" :disabled="busy" :invalid-message="$t(error.aiida_user_last_name)" class="field"></cv-text-input>
            <cv-text-input :label="$t('settings.aiida_user_institution')" v-model.trim="aiida_user_institution" :disabled="busy" :invalid-message="$t(error.aiida_user_institution)" class="field"></cv-text-input>

            <!-- Apps -->
            <h4 class="section">{{ $t("settings.apps_section") }}</h4>
            <cv-text-area :label="$t('settings.default_apps')" v-model="default_apps_text" :placeholder="$t('settings.default_apps_placeholder')" :helper-text="$t('settings.default_apps_helper')" :disabled="busy" :invalid-message="$t(error.default_apps)" ref="default_apps" rows="3" class="field"></cv-text-area>

            <!-- Remote computer -->
            <h4 class="section">{{ $t("settings.computer_section") }}</h4>
            <div class="bx--form__helper-text">{{ $t("settings.computer_helper") }}</div>
            <cv-toggle value="computerEnabled" :label="$t('settings.computer_enabled')" v-model="computer_enabled" :disabled="busy" class="toggle">
              <template slot="text-left">{{ $t("settings.disabled") }}</template>
              <template slot="text-right">{{ $t("settings.enabled") }}</template>
            </cv-toggle>
            <template v-if="computer_enabled">
              <cv-text-input :label="$t('settings.computer_label')" v-model.trim="computer_label" :disabled="busy" :invalid-message="$t(error.computer_label)" ref="computer_label" class="field"></cv-text-input>
              <cv-text-input :label="$t('settings.computer_hostname')" v-model.trim="computer_hostname" :helper-text="$t('settings.computer_hostname_helper')" :disabled="busy" :invalid-message="$t(error.computer_hostname)" ref="computer_hostname" class="field"></cv-text-input>
              <cv-text-input :label="$t('settings.computer_username')" v-model.trim="computer_username" :disabled="busy" :invalid-message="$t(error.computer_username)" ref="computer_username" class="field"></cv-text-input>
              <cv-number-input :label="$t('settings.computer_port')" v-model="computer_port" :min="1" :max="65535" :disabled="busy" :invalid-message="$t(error.computer_port)" class="field"></cv-number-input>
              <cv-text-input :label="$t('settings.computer_workdir')" v-model.trim="computer_workdir" :helper-text="$t('settings.computer_workdir_helper')" :disabled="busy" :invalid-message="$t(error.computer_workdir)" ref="computer_workdir" class="field"></cv-text-input>
              <cv-dropdown :label="$t('settings.computer_scheduler')" v-model="computer_scheduler" :disabled="busy" class="field">
                <cv-dropdown-item value="core.direct">{{ $t("settings.sched_direct") }}</cv-dropdown-item>
                <cv-dropdown-item value="core.slurm">{{ $t("settings.sched_slurm") }}</cv-dropdown-item>
                <cv-dropdown-item value="core.pbspro">{{ $t("settings.sched_pbspro") }}</cv-dropdown-item>
                <cv-dropdown-item value="core.torque">{{ $t("settings.sched_torque") }}</cv-dropdown-item>
                <cv-dropdown-item value="core.sge">{{ $t("settings.sched_sge") }}</cv-dropdown-item>
                <cv-dropdown-item value="core.lsf">{{ $t("settings.sched_lsf") }}</cv-dropdown-item>
              </cv-dropdown>
              <cv-text-input :label="$t('settings.computer_mpirun')" v-model.trim="computer_mpirun" :helper-text="$t('settings.computer_mpirun_helper')" :disabled="busy" :invalid-message="$t(error.computer_mpirun)" class="field"></cv-text-input>
              <cv-number-input :label="$t('settings.computer_mpiprocs')" v-model="computer_mpiprocs" :min="1" :max="4096" :disabled="busy" :invalid-message="$t(error.computer_mpiprocs)" class="field"></cv-number-input>
              <cv-text-input :label="$t('settings.computer_description')" v-model.trim="computer_description" :disabled="busy" :invalid-message="$t(error.computer_description)" class="field"></cv-text-input>
            </template>

            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification kind="error" :title="$t('action.configure-module')" :description="error.configureModule" :showCloseButton="false" />
              </cv-column>
            </cv-row>
            <NsButton kind="primary" :icon="Save20" :loading="loading.configureModule" :disabled="busy">{{ $t("settings.save") }}</NsButton>
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <!-- SSH key + registered computers + connection test -->
    <cv-row v-if="!loading.getConfiguration && container_running">
      <cv-column>
        <cv-tile light>
          <h4 class="section-first">{{ $t("settings.sshkey_title") }}</h4>
          <div class="bx--form__helper-text">{{ $t("settings.sshkey_desc") }}</div>
          <pre v-if="ssh_public_key" class="console">{{ ssh_public_key }}</pre>
          <div v-else class="bx--form__helper-text">{{ $t("settings.sshkey_unavailable") }}</div>

          <h4 class="section">{{ $t("settings.computers_title") }}</h4>
          <ul v-if="computers.length" class="computers">
            <li v-for="c in computers" :key="c">
              <code>{{ c }}</code>
              <NsButton kind="ghost" size="small" :icon="Connect20" :loading="loading.testComputer === c" :disabled="!!loading.testComputer || !app_up" @click="testComputer(c)" class="inline-button">{{ $t("settings.test_computer") }}</NsButton>
            </li>
          </ul>
          <div v-else class="bx--form__helper-text">—</div>
          <NsInlineNotification v-if="error.testComputer" kind="error" :title="$t('action.test-computer')" :description="error.testComputer" :showCloseButton="false" class="info-tile" />
          <div v-if="test_output !== null" class="field">
            <div class="bx--label">{{ $t("settings.test_result") }}: {{ test_success ? $t("settings.test_success") : $t("settings.test_failed") }}</div>
            <pre class="console">{{ test_output }}</pre>
          </div>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import { QueryParamService, UtilService, TaskService, IconService, PageTitleService } from "@nethserver/ns8-ui-lib";
import Connect20 from "@carbon/icons-vue/es/connect/20";

const APP_RE = /^[A-Za-z0-9_.:/@+=-]+$/;
const LABEL_RE = /^[A-Za-z0-9_.-]*$/;

export default {
  name: "Settings",
  mixins: [TaskService, IconService, UtilService, QueryParamService, PageTitleService],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: { page: "settings" },
      urlCheckInterval: null,
      Connect20,
      host: "",
      lets_encrypt: false,
      http2https: true,
      password: "",
      password_set: false,
      aiida_user_email: "",
      aiida_user_first_name: "",
      aiida_user_last_name: "",
      aiida_user_institution: "",
      default_apps_text: "",
      computer_enabled: false,
      computer_label: "gpu-node",
      computer_hostname: "",
      computer_username: "",
      computer_port: 22,
      computer_workdir: "",
      computer_scheduler: "core.direct",
      computer_mpirun: "mpirun -np {tot_num_mpiprocs}",
      computer_mpiprocs: 4,
      computer_description: "",
      url: "",
      container_running: false,
      app_up: false,
      aiida_version: "",
      aiidalab_version: "",
      ssh_public_key: "",
      computers: [],
      test_output: null,
      test_success: false,
      loading: { getConfiguration: false, configureModule: false, testComputer: "" },
      error: {
        getConfiguration: "", configureModule: "", testComputer: "",
        host: "", password: "", aiida_user_email: "", aiida_user_first_name: "", aiida_user_last_name: "", aiida_user_institution: "", default_apps: "",
        computer_label: "", computer_hostname: "", computer_username: "", computer_port: "", computer_workdir: "", computer_mpirun: "", computer_mpiprocs: "", computer_description: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    busy() {
      return this.loading.getConfiguration || this.loading.configureModule;
    },
    default_apps() {
      return this.default_apps_text.split(/[\r\n,]+/).map((p) => p.trim()).filter((p) => p.length > 0);
    },
    statusTitle() {
      if (!this.container_running) return this.$t("settings.status_stopped");
      if (!this.app_up) return this.$t("settings.status_starting");
      return this.$t("settings.status_up", { aiida: this.aiida_version || "?", aiidalab: this.aiidalab_version || "?" });
    },
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.getConfigurationAborted);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.getConfigurationCompleted);
      const res = await to(this.createModuleTaskForApp(this.instanceName, { action: taskAction, extra: { title: this.$t("action." + taskAction), isNotificationHidden: true, eventId } }));
      const err = res[0];
      if (err) {
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const c = taskResult.output;
      this.host = c.host || "";
      this.lets_encrypt = !!c.lets_encrypt;
      this.http2https = c.http2https !== false;
      this.password = "";
      this.password_set = !!c.password_set;
      this.aiida_user_email = c.aiida_user_email || "";
      this.aiida_user_first_name = c.aiida_user_first_name || "";
      this.aiida_user_last_name = c.aiida_user_last_name || "";
      this.aiida_user_institution = c.aiida_user_institution || "";
      this.default_apps_text = (c.default_apps || []).join("\n");
      this.computer_enabled = !!c.computer_enabled;
      this.computer_label = c.computer_label || "gpu-node";
      this.computer_hostname = c.computer_hostname || "";
      this.computer_username = c.computer_username || "";
      this.computer_port = c.computer_port || 22;
      this.computer_workdir = c.computer_workdir || "";
      this.computer_scheduler = c.computer_scheduler || "core.direct";
      this.computer_mpirun = c.computer_mpirun || "mpirun -np {tot_num_mpiprocs}";
      this.computer_mpiprocs = c.computer_mpiprocs || 4;
      this.computer_description = c.computer_description || "";
      this.url = c.url || "";
      this.container_running = !!c.container_running;
      this.app_up = !!c.app_up;
      this.aiida_version = c.aiida_version || "";
      this.aiidalab_version = c.aiidalab_version || "";
      this.ssh_public_key = c.ssh_public_key || "";
      this.computers = c.computers || [];
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let ok = true;
      const fail = (field, msg) => {
        this.error[field] = msg;
        if (ok && this.$refs[field]) this.focusElement(field);
        ok = false;
      };
      if (!this.host) fail("host", "common.required");
      if (!this.password && !this.password_set) fail("password", "settings.password_required");
      if (this.default_apps.some((a) => !APP_RE.test(a))) fail("default_apps", "settings.invalid_app_name");
      if (this.computer_enabled) {
        for (const f of ["computer_label", "computer_hostname", "computer_username", "computer_workdir"]) {
          if (!this[f]) fail(f, "common.required");
        }
        if (!LABEL_RE.test(this.computer_label)) fail("computer_label", "settings.invalid_app_name");
        if (this.computer_label === "localhost") fail("computer_label", "settings.label_reserved");
        if (this.computer_workdir && !this.computer_workdir.startsWith("/")) fail("computer_workdir", "settings.workdir_must_be_absolute");
      }
      return ok;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusSet = false;
      for (const e of validationErrors) {
        if (e.field !== "(root)") {
          const detail = e.value && typeof e.value === "string" ? ` (${e.value})` : "";
          this.error[e.field] = this.$t("settings." + e.error) + detail;
          if (!focusSet && this.$refs[e.field]) {
            this.focusElement(e.field);
            focusSet = true;
          }
        }
      }
    },
    async configureModule() {
      if (!this.validateConfigureModule()) return;
      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.configureModuleAborted);
      this.core.$root.$once(`${taskAction}-validation-failed-${eventId}`, this.configureModuleValidationFailed);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.configureModuleCompleted);
      const data = {
        host: this.host,
        lets_encrypt: this.lets_encrypt,
        http2https: this.http2https,
        password: this.password,
        aiida_user_email: this.aiida_user_email,
        aiida_user_first_name: this.aiida_user_first_name,
        aiida_user_last_name: this.aiida_user_last_name,
        aiida_user_institution: this.aiida_user_institution,
        default_apps: this.default_apps,
        computer_enabled: this.computer_enabled,
        computer_label: this.computer_label,
        computer_hostname: this.computer_hostname,
        computer_username: this.computer_username,
        computer_port: Number(this.computer_port),
        computer_workdir: this.computer_workdir,
        computer_scheduler: this.computer_scheduler,
        computer_mpirun: this.computer_mpirun,
        computer_mpiprocs: Number(this.computer_mpiprocs),
        computer_description: this.computer_description,
      };
      const res = await to(this.createModuleTaskForApp(this.instanceName, {
        action: taskAction,
        data,
        extra: { title: this.$t("settings.configure_instance", { instance: this.instanceName }), description: this.$t("common.processing"), eventId },
      }));
      const err = res[0];
      if (err) {
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;
      this.getConfiguration();
    },
    async testComputer(label) {
      this.loading.testComputer = label;
      this.error.testComputer = "";
      this.test_output = null;
      const taskAction = "test-computer";
      const eventId = this.getUuid();
      this.core.$root.$once(`${taskAction}-aborted-${eventId}`, this.testComputerAborted);
      this.core.$root.$once(`${taskAction}-completed-${eventId}`, this.testComputerCompleted);
      const res = await to(this.createModuleTaskForApp(this.instanceName, {
        action: taskAction,
        data: { label },
        extra: { title: this.$t("action." + taskAction), isNotificationHidden: true, eventId },
      }));
      const err = res[0];
      if (err) {
        this.error.testComputer = this.getErrorMessage(err);
        this.loading.testComputer = "";
      }
    },
    testComputerAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.testComputer = this.$t("error.generic_error");
      this.loading.testComputer = "";
    },
    testComputerCompleted(taskContext, taskResult) {
      this.loading.testComputer = "";
      const out = taskResult.output || {};
      this.test_success = !!out.success;
      this.test_output = out.output || "";
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.field { margin-top: $spacing-06; }
.toggle { margin-top: $spacing-06; }
.info-tile { margin-top: $spacing-06; }
.connect { margin-top: $spacing-04; }
.section { margin-top: $spacing-07; margin-bottom: $spacing-03; }
.section-first { margin-bottom: $spacing-03; }
.console { font-family: monospace; white-space: pre-wrap; word-break: break-all; background: #f4f4f4; padding: $spacing-05; margin-top: $spacing-03; }
.computers { margin-top: $spacing-03; }
.computers li { display: flex; align-items: center; gap: $spacing-04; margin-bottom: $spacing-02; }
.inline-button { margin-left: $spacing-03; }
</style>
