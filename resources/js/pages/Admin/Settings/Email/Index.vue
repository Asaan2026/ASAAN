<template>
    <AdminLayout :title="$t('Email Settings')">
        <template #default>
            <Head :title="$t('Email Settings')" />
            <div class="space-y-6">
                <!-- Header -->
                <div
                    class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
                >
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-900 dark:text-white"
                        >
                            {{ $t('Email Settings') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Configure email delivery and manage email templates',
                                )
                            }}
                        </p>
                    </div>
                    <div v-if="activeTab === 'configuration'">
                        <button
                            @click="saveConfiguration"
                            :disabled="form.processing"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            <Save
                                v-if="!form.processing"
                                class="mr-2 h-4 w-4"
                            />
                            <svg
                                v-else
                                class="mr-2 h-4 w-4 animate-spin"
                                fill="none"
                                viewBox="0 0 24 24"
                            >
                                <circle
                                    class="opacity-25"
                                    cx="12"
                                    cy="12"
                                    r="10"
                                    stroke="currentColor"
                                    stroke-width="4"
                                ></circle>
                                <path
                                    class="opacity-75"
                                    fill="currentColor"
                                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                ></path>
                            </svg>
                            {{
                                form.processing
                                    ? $t('Saving...')
                                    : $t('Save Configuration')
                            }}
                        </button>
                    </div>
                </div>

                <!-- Tabs -->
                <div
                    class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div
                        class="border-b border-gray-200 bg-gray-50/50 dark:border-gray-700 dark:bg-gray-800"
                    >
                        <nav
                            class="flex space-x-8 px-6"
                            :aria-label="$t('Tabs')"
                        >
                            <button
                                @click="activeTab = 'configuration'"
                                :class="[
                                    activeTab === 'configuration'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap transition-colors duration-200',
                                ]"
                            >
                                <Settings
                                    class="mr-2 h-4 w-4"
                                    :class="
                                        activeTab === 'configuration'
                                            ? 'text-blue-500'
                                            : 'text-gray-400 group-hover:text-gray-500'
                                    "
                                />
                                {{ $t('Configuration') }}
                            </button>
                            <button
                                @click="activeTab = 'templates'"
                                :class="[
                                    activeTab === 'templates'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap transition-colors duration-200',
                                ]"
                            >
                                <FileText
                                    class="mr-2 h-4 w-4"
                                    :class="
                                        activeTab === 'templates'
                                            ? 'text-blue-500'
                                            : 'text-gray-400 group-hover:text-gray-500'
                                    "
                                />
                                {{ $t('Email Templates') }}
                            </button>
                        </nav>
                    </div>

                    <!-- Tab Content -->
                    <div>
                        <!-- Configuration Tab -->
                        <div
                            v-show="activeTab === 'configuration'"
                            class="p-6 sm:p-8"
                        >
                            <form @submit.prevent="saveConfiguration">
                                <!-- General Settings -->
                                <div class="mb-8">
                                    <h3
                                        class="mb-6 flex items-center gap-2 text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        <Settings
                                            class="h-5 w-5 text-gray-400"
                                        />
                                        {{ $t('General Configuration') }}
                                    </h3>
                                    <div
                                        class="grid grid-cols-1 gap-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Mail Driver') }}</label
                                            >
                                            <div class="relative">
                                                <div
                                                    class="padding-l-3 pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                                                >
                                                    <Server
                                                        class="h-4 w-4 text-gray-400"
                                                    />
                                                </div>
                                                <select
                                                    v-model="form.mail_driver"
                                                    class="block w-full rounded-lg border border-gray-300 bg-white py-2.5 pr-10 pl-10 text-sm shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                >
                                                    <option
                                                        v-for="(
                                                            label, value
                                                        ) in drivers"
                                                        :key="value"
                                                        :value="value"
                                                    >
                                                        {{ label }}
                                                    </option>
                                                </select>
                                            </div>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('From Email') }}</label
                                            >
                                            <input
                                                v-model="form.mail_from_address"
                                                type="email"
                                                required
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('From Name') }}</label
                                            >
                                            <input
                                                v-model="form.mail_from_name"
                                                type="text"
                                                required
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t(
                                                        'Reply-To Email (Optional)',
                                                    )
                                                }}</label
                                            >
                                            <input
                                                v-model="form.reply_to_email"
                                                type="email"
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <!-- SMTP Configuration -->
                                <div
                                    v-if="form.mail_driver === 'smtp'"
                                    class="mb-8 border-t border-gray-100 pt-6 dark:border-gray-700"
                                >
                                    <h3
                                        class="mb-6 flex items-center gap-2 text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        <Mail class="h-5 w-5 text-gray-400" />
                                        {{ $t('SMTP Server Details') }}
                                    </h3>
                                    <div
                                        class="grid grid-cols-1 gap-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('SMTP Host') }}</label
                                            >
                                            <input
                                                v-model="form.smtp_host"
                                                type="text"
                                                placeholder="smtp.gmail.com"
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('SMTP Port') }}</label
                                            >
                                            <input
                                                v-model="form.smtp_port"
                                                type="number"
                                                placeholder="587"
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('SMTP Username')
                                                }}</label
                                            >
                                            <input
                                                v-model="form.smtp_username"
                                                type="text"
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('SMTP Password')
                                                }}</label
                                            >
                                            <div class="relative">
                                                <input
                                                    v-model="form.smtp_password"
                                                    :type="
                                                        showPassword
                                                            ? 'text'
                                                            : 'password'
                                                    "
                                                    placeholder="••••••••"
                                                    class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 pr-10 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                />
                                                <button
                                                    type="button"
                                                    @click="
                                                        showPassword =
                                                            !showPassword
                                                    "
                                                    class="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-500 focus:outline-none dark:hover:text-gray-300"
                                                >
                                                    <Eye
                                                        v-if="!showPassword"
                                                        class="h-4 w-4"
                                                    />
                                                    <EyeOff
                                                        v-else
                                                        class="h-4 w-4"
                                                    />
                                                </button>
                                            </div>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Encryption') }}</label
                                            >
                                            <div class="relative">
                                                <div
                                                    class="padding-l-3 pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                                                >
                                                    <Shield
                                                        class="h-4 w-4 text-gray-400"
                                                    />
                                                </div>
                                                <select
                                                    v-model="
                                                        form.smtp_encryption
                                                    "
                                                    class="block w-full rounded-lg border border-gray-300 bg-white py-2.5 pr-10 pl-10 text-sm shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                >
                                                    <option value="tls">
                                                        TLS
                                                    </option>
                                                    <option value="ssl">
                                                        SSL
                                                    </option>
                                                    <option value="none">
                                                        {{ $t('None') }}
                                                    </option>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Amazon SES Configuration -->
                                <div
                                    v-if="form.mail_driver === 'ses'"
                                    class="mb-8 border-t border-gray-100 pt-6 dark:border-gray-700"
                                >
                                    <h3
                                        class="mb-6 flex items-center gap-2 text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        <Server class="h-5 w-5 text-gray-400" />
                                        {{ $t('Amazon SES Configuration') }}
                                    </h3>
                                    <div
                                        class="grid grid-cols-1 gap-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('Access Key ID')
                                                }}</label
                                            >
                                            <input
                                                v-model="form.ses_key"
                                                type="text"
                                                :placeholder="
                                                    configuration.ses_key_masked ||
                                                    'AKIA...'
                                                "
                                                class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{
                                                    $t('Secret Access Key')
                                                }}</label
                                            >
                                            <div class="relative">
                                                <input
                                                    v-model="form.ses_secret"
                                                    :type="
                                                        showSesSecret
                                                            ? 'text'
                                                            : 'password'
                                                    "
                                                    :placeholder="
                                                        configuration.ses_secret_masked ||
                                                        '••••••••'
                                                    "
                                                    class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 pr-10 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                />
                                                <button
                                                    type="button"
                                                    @click="
                                                        showSesSecret =
                                                            !showSesSecret
                                                    "
                                                    class="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-500 focus:outline-none dark:hover:text-gray-300"
                                                >
                                                    <Eye
                                                        v-if="!showSesSecret"
                                                        class="h-4 w-4"
                                                    />
                                                    <EyeOff
                                                        v-else
                                                        class="h-4 w-4"
                                                    />
                                                </button>
                                            </div>
                                        </div>
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Region') }}</label
                                            >
                                            <div class="relative">
                                                <div
                                                    class="padding-l-3 pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                                                >
                                                    <Globe
                                                        class="h-4 w-4 text-gray-400"
                                                    />
                                                </div>
                                                <select
                                                    v-model="form.ses_region"
                                                    class="block w-full rounded-lg border border-gray-300 bg-white py-2.5 pr-10 pl-10 text-sm shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                >
                                                    <option value="us-east-1">
                                                        {{
                                                            $t(
                                                                'US East (N. Virginia)',
                                                            )
                                                        }}
                                                    </option>
                                                    <option value="us-west-2">
                                                        {{
                                                            $t(
                                                                'US West (Oregon)',
                                                            )
                                                        }}
                                                    </option>
                                                    <option value="eu-west-1">
                                                        {{ $t('EU (Ireland)') }}
                                                    </option>
                                                    <option
                                                        value="ap-southeast-1"
                                                    >
                                                        {{
                                                            $t(
                                                                'Asia Pacific (Singapore)',
                                                            )
                                                        }}
                                                    </option>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Postmark Configuration -->
                                <div
                                    v-if="form.mail_driver === 'postmark'"
                                    class="mb-8 border-t border-gray-100 pt-6 dark:border-gray-700"
                                >
                                    <h3
                                        class="mb-6 flex items-center gap-2 text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        <Mail class="h-5 w-5 text-gray-400" />
                                        {{ $t('Postmark Configuration') }}
                                    </h3>
                                    <div
                                        class="grid grid-cols-1 gap-6 md:grid-cols-2"
                                    >
                                        <div>
                                            <label
                                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                                >{{ $t('Server Token') }}</label
                                            >
                                            <div class="relative">
                                                <input
                                                    v-model="
                                                        form.postmark_token
                                                    "
                                                    :type="
                                                        showPostmarkToken
                                                            ? 'text'
                                                            : 'password'
                                                    "
                                                    :placeholder="
                                                        configuration.postmark_token_masked ||
                                                        '••••••••'
                                                    "
                                                    class="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2.5 pr-10 text-sm placeholder-gray-400 shadow-sm transition-shadow duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700"
                                                />
                                                <button
                                                    type="button"
                                                    @click="
                                                        showPostmarkToken =
                                                            !showPostmarkToken
                                                    "
                                                    class="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-gray-500 focus:outline-none dark:hover:text-gray-300"
                                                >
                                                    <Eye
                                                        v-if="
                                                            !showPostmarkToken
                                                        "
                                                        class="h-4 w-4"
                                                    />
                                                    <EyeOff
                                                        v-else
                                                        class="h-4 w-4"
                                                    />
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Test Connection Status -->
                                <div
                                    v-if="configuration.last_test_at"
                                    class="mb-6 rounded-xl border p-4"
                                    :class="
                                        configuration.last_test_status ===
                                        'success'
                                            ? 'border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-900/10'
                                            : 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/10'
                                    "
                                >
                                    <div class="flex items-start gap-3">
                                        <div class="mt-0.5 flex-shrink-0">
                                            <Check
                                                v-if="
                                                    configuration.last_test_status ===
                                                    'success'
                                                "
                                                class="h-5 w-5 text-green-600 dark:text-green-400"
                                            />
                                            <AlertCircle
                                                v-else
                                                class="h-5 w-5 text-red-600 dark:text-red-400"
                                            />
                                        </div>
                                        <div>
                                            <h4
                                                :class="
                                                    configuration.last_test_status ===
                                                    'success'
                                                        ? 'text-green-800 dark:text-green-300'
                                                        : 'text-red-800 dark:text-red-300'
                                                "
                                                class="text-sm font-semibold"
                                            >
                                                {{
                                                    configuration.last_test_message
                                                }}
                                            </h4>
                                            <p
                                                :class="
                                                    configuration.last_test_status ===
                                                    'success'
                                                        ? 'text-green-700 dark:text-green-400'
                                                        : 'text-red-700 dark:text-red-400'
                                                "
                                                class="mt-1 text-xs opacity-80"
                                            >
                                                {{ $t('Last tested:') }}
                                                <DateDisplay
                                                    :value="
                                                        configuration.last_test_at
                                                    "
                                                    time
                                                />
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <!-- Action Buttons -->
                                <div
                                    class="mt-8 flex flex-wrap items-center gap-4 border-t border-gray-100 pt-6 dark:border-gray-700"
                                >
                                    <button
                                        type="button"
                                        @click="testConnection"
                                        :disabled="testingConnection"
                                        class="inline-flex items-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-all duration-200 hover:bg-gray-50 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:outline-none disabled:opacity-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                                    >
                                        <Play
                                            v-if="!testingConnection"
                                            class="mr-2 h-4 w-4 text-green-500"
                                        />
                                        <svg
                                            v-else
                                            class="mr-2 h-4 w-4 animate-spin text-green-500"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                        >
                                            <circle
                                                class="opacity-25"
                                                cx="12"
                                                cy="12"
                                                r="10"
                                                stroke="currentColor"
                                                stroke-width="4"
                                            ></circle>
                                            <path
                                                class="opacity-75"
                                                fill="currentColor"
                                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                            ></path>
                                        </svg>
                                        {{
                                            testingConnection
                                                ? $t('Testing...')
                                                : $t('Test Connection')
                                        }}
                                    </button>

                                    <button
                                        type="button"
                                        @click="showSendTestDialog = true"
                                        class="inline-flex items-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-all duration-200 hover:bg-gray-50 focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                                    >
                                        <Mail
                                            class="mr-2 h-4 w-4 text-purple-500"
                                        />
                                        {{ $t('Send Test Email') }}
                                    </button>

                                    <div class="flex-1"></div>

                                    <button
                                        type="submit"
                                        :disabled="form.processing"
                                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                                    >
                                        <Save
                                            v-if="!form.processing"
                                            class="mr-2 h-4 w-4"
                                        />
                                        <svg
                                            v-else
                                            class="mr-2 h-4 w-4 animate-spin"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                        >
                                            <circle
                                                class="opacity-25"
                                                cx="12"
                                                cy="12"
                                                r="10"
                                                stroke="currentColor"
                                                stroke-width="4"
                                            ></circle>
                                            <path
                                                class="opacity-75"
                                                fill="currentColor"
                                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                            ></path>
                                        </svg>
                                        {{
                                            form.processing
                                                ? $t('Saving...')
                                                : $t('Save Configuration')
                                        }}
                                    </button>
                                </div>
                            </form>
                        </div>

                        <!-- Email Templates Tab -->
                        <div
                            v-show="activeTab === 'templates'"
                            class="p-6 sm:p-8"
                        >
                            <div
                                v-for="(
                                    categoryTemplates, category
                                ) in templates"
                                :key="category"
                                class="mb-8 last:mb-0"
                            >
                                <div class="mb-4 flex items-center gap-2">
                                    <FileText class="h-5 w-5 text-gray-400" />
                                    <h3
                                        class="text-lg font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ categories[category] }}
                                    </h3>
                                </div>

                                <div class="space-y-3">
                                    <div
                                        v-for="template in categoryTemplates"
                                        :key="template.id"
                                        class="flex items-center justify-between rounded-xl border border-gray-200 bg-gray-50 p-5 transition-all duration-200 hover:border-gray-300 hover:shadow-sm dark:border-gray-700 dark:bg-gray-700/40 dark:hover:border-gray-600"
                                    >
                                        <div
                                            class="flex flex-1 items-start gap-4"
                                        >
                                            <div class="mt-1 flex-shrink-0">
                                                <span
                                                    :class="
                                                        template.is_active
                                                            ? 'border border-green-200 bg-green-100 text-green-700 dark:border-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                            : 'border border-gray-200 bg-gray-100 text-gray-500 dark:border-gray-600 dark:bg-gray-600 dark:text-gray-400'
                                                    "
                                                    class="inline-flex items-center rounded-lg px-2.5 py-1 text-xs font-medium"
                                                >
                                                    <CheckCircle2
                                                        v-if="
                                                            template.is_active
                                                        "
                                                        class="mr-1.5 h-3 w-3"
                                                    />
                                                    <X
                                                        v-else
                                                        class="mr-1.5 h-3 w-3"
                                                    />
                                                    {{
                                                        template.is_active
                                                            ? $t('Active')
                                                            : $t('Inactive')
                                                    }}
                                                </span>
                                            </div>
                                            <div class="min-w-0 flex-1">
                                                <h4
                                                    class="mb-1 font-semibold text-gray-900 dark:text-white"
                                                >
                                                    {{ template.name }}
                                                </h4>
                                                <p
                                                    class="mb-2 text-sm text-gray-600 dark:text-gray-400"
                                                >
                                                    {{ template.description }}
                                                </p>
                                                <div
                                                    class="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-500"
                                                >
                                                    <span
                                                        class="flex items-center gap-1.5 rounded-md border border-gray-200 bg-white px-2 py-1 dark:border-gray-700 dark:bg-gray-800"
                                                    >
                                                        <Mail
                                                            class="h-3 w-3 text-gray-400"
                                                        />
                                                        <span
                                                            class="max-w-[200px] truncate"
                                                            >{{
                                                                $t('Subject:')
                                                            }}
                                                            {{
                                                                template.subject
                                                            }}</span
                                                        >
                                                    </span>
                                                    <span
                                                        class="flex items-center gap-1.5 rounded-md border border-gray-200 bg-white px-2 py-1 dark:border-gray-700 dark:bg-gray-800"
                                                    >
                                                        <CheckCircle2
                                                            class="h-3 w-3 text-gray-400"
                                                        />
                                                        {{
                                                            $t('{count} sent', {
                                                                count: template.times_sent,
                                                            })
                                                        }}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>

                                        <div
                                            class="ml-4 flex items-center gap-2"
                                        >
                                            <button
                                                @click="editTemplate(template)"
                                                class="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm transition-all hover:border-blue-200 hover:bg-gray-50 hover:text-blue-600 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:border-blue-800 dark:hover:bg-gray-700 dark:hover:text-blue-400"
                                                :title="$t('Edit Template')"
                                            >
                                                <Edit2 class="h-3.5 w-3.5" />
                                                {{ $t('Edit') }}
                                            </button>
                                            <button
                                                @click="
                                                    toggleTemplateStatus(
                                                        template.id,
                                                    )
                                                "
                                                :class="
                                                    template.is_active
                                                        ? 'border border-gray-200 bg-white text-gray-700 hover:border-red-200 hover:bg-red-50 hover:text-red-600 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:border-red-800 dark:hover:bg-red-900/20 dark:hover:text-red-400'
                                                        : 'border border-gray-200 bg-white text-gray-700 hover:border-green-200 hover:bg-green-50 hover:text-green-600 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:border-green-800 dark:hover:bg-green-900/20 dark:hover:text-green-400'
                                                "
                                                class="inline-flex w-[100px] items-center justify-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium shadow-sm transition-all"
                                                :title="
                                                    template.is_active
                                                        ? $t('Disable Template')
                                                        : $t('Enable Template')
                                                "
                                            >
                                                <Power class="h-3.5 w-3.5" />
                                                {{
                                                    template.is_active
                                                        ? $t('Disable')
                                                        : $t('Enable')
                                                }}
                                            </button>
                                            <button
                                                @click="
                                                    sendTestTemplate(template)
                                                "
                                                class="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm transition-all hover:border-purple-200 hover:bg-purple-50 hover:text-purple-600 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:border-purple-800 dark:hover:bg-purple-900/20 dark:hover:text-purple-400"
                                                :title="$t('Send Test Email')"
                                            >
                                                <Mail class="h-3.5 w-3.5" />
                                                {{ $t('Test') }}
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Edit Template Modal -->
                <div
                    v-if="editingTemplate"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
                >
                    <div
                        class="flex max-h-[90vh] w-full max-w-4xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-gray-800"
                    >
                        <div
                            class="flex flex-shrink-0 items-center justify-between border-b border-gray-200 p-6 dark:border-gray-700"
                        >
                            <div class="flex items-center gap-3">
                                <div
                                    class="rounded-lg bg-blue-100 p-2 dark:bg-blue-900/30"
                                >
                                    <Edit2
                                        class="h-5 w-5 text-blue-600 dark:text-blue-400"
                                    />
                                </div>
                                <h3
                                    class="text-lg font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Edit Email Template') }}
                                </h3>
                            </div>
                            <button
                                type="button"
                                @click="editingTemplate = null"
                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                            >
                                <X class="h-5 w-5" />
                            </button>
                        </div>

                        <form
                            @submit.prevent="saveTemplate"
                            class="flex-1 overflow-y-auto"
                        >
                            <div class="space-y-6 p-6">
                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Subject Line') }}</label
                                    >
                                    <input
                                        v-model="templateForm.subject"
                                        type="text"
                                        required
                                        :placeholder="
                                            $t('Enter email subject...')
                                        "
                                        class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 transition-all focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    />
                                </div>

                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('HTML Content') }}</label
                                    >
                                    <TiptapEditor
                                        v-model="templateForm.html_content"
                                        :placeholder="
                                            $t(
                                                'Email HTML content with formatting...',
                                            )
                                        "
                                    />
                                    <div
                                        class="mt-2 rounded-lg border border-blue-200 bg-blue-50 p-3 dark:border-blue-800 dark:bg-blue-900/10"
                                    >
                                        <p
                                            class="mb-1 text-xs font-medium text-blue-700 dark:text-blue-300"
                                        >
                                            {{ $t('Available Variables:') }}
                                        </p>
                                        <p
                                            class="text-xs text-blue-600 dark:text-blue-400"
                                        >
                                            {customer_name}, {order_number},
                                            {store_name}, {order_total},
                                            {tracking_number}
                                        </p>
                                    </div>
                                </div>

                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Plain Text Content (Optional)')
                                        }}</label
                                    >
                                    <textarea
                                        v-model="
                                            templateForm.plain_text_content
                                        "
                                        rows="8"
                                        :placeholder="
                                            $t('Fallback plain text version...')
                                        "
                                        class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 font-mono text-sm text-gray-900 transition-all focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    ></textarea>
                                </div>
                            </div>

                            <div
                                class="flex flex-shrink-0 justify-end gap-3 border-t border-gray-200 bg-gray-50 p-6 dark:border-gray-700 dark:bg-gray-900/50"
                            >
                                <button
                                    type="button"
                                    @click="editingTemplate = null"
                                    class="rounded-xl border border-gray-300 bg-white px-5 py-2.5 font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    {{ $t('Cancel') }}
                                </button>
                                <button
                                    type="submit"
                                    :disabled="templateForm.processing"
                                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    <Save
                                        v-if="!templateForm.processing"
                                        class="mr-2 h-4 w-4"
                                    />
                                    <svg
                                        v-else
                                        class="h-4 w-4 animate-spin"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                    >
                                        <circle
                                            class="opacity-25"
                                            cx="12"
                                            cy="12"
                                            r="10"
                                            stroke="currentColor"
                                            stroke-width="4"
                                        ></circle>
                                        <path
                                            class="opacity-75"
                                            fill="currentColor"
                                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                        ></path>
                                    </svg>
                                    {{
                                        templateForm.processing
                                            ? $t('Saving...')
                                            : $t('Save Template')
                                    }}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Send Test Email Dialog -->
                <div
                    v-if="showSendTestDialog"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
                >
                    <div
                        class="w-full max-w-md overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-gray-800"
                    >
                        <div
                            class="flex items-center justify-between border-b border-gray-200 p-6 dark:border-gray-700"
                        >
                            <div class="flex items-center gap-3">
                                <div
                                    class="rounded-lg bg-purple-100 p-2 dark:bg-purple-900/30"
                                >
                                    <Mail
                                        class="h-5 w-5 text-purple-600 dark:text-purple-400"
                                    />
                                </div>
                                <h3
                                    class="text-lg font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Send Test Email') }}
                                </h3>
                            </div>
                            <button
                                type="button"
                                @click="showSendTestDialog = false"
                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                            >
                                <X class="h-5 w-5" />
                            </button>
                        </div>

                        <form @submit.prevent="sendTest">
                            <div class="p-6">
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Test Email Address') }}</label
                                >
                                <input
                                    v-model="testEmail"
                                    type="email"
                                    required
                                    placeholder="your@email.com"
                                    class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 transition-all focus:border-transparent focus:ring-2 focus:ring-purple-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                />
                                <p
                                    class="mt-2 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'A test email will be sent to this address using your current configuration.',
                                        )
                                    }}
                                </p>
                            </div>

                            <div
                                class="flex justify-end gap-3 border-t border-gray-200 bg-gray-50 p-6 dark:border-gray-700 dark:bg-gray-900/50"
                            >
                                <button
                                    type="button"
                                    @click="showSendTestDialog = false"
                                    class="rounded-xl border border-gray-300 bg-white px-5 py-2.5 font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    {{ $t('Cancel') }}
                                </button>
                                <button
                                    type="submit"
                                    :disabled="sendingTest"
                                    class="inline-flex items-center gap-2 rounded-xl bg-purple-600 px-6 py-2.5 font-medium text-white shadow-sm transition-all hover:bg-purple-700 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    <Mail v-if="!sendingTest" class="h-4 w-4" />
                                    <svg
                                        v-else
                                        class="h-4 w-4 animate-spin"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                    >
                                        <circle
                                            class="opacity-25"
                                            cx="12"
                                            cy="12"
                                            r="10"
                                            stroke="currentColor"
                                            stroke-width="4"
                                        ></circle>
                                        <path
                                            class="opacity-75"
                                            fill="currentColor"
                                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                        ></path>
                                    </svg>
                                    {{
                                        sendingTest
                                            ? $t('Sending...')
                                            : $t('Send Test')
                                    }}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </template>
    </AdminLayout>
</template>

<script setup lang="ts">
import TiptapEditor from '@/components/Admin/TiptapEditor.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router } from '@inertiajs/vue3';
import {
    AlertCircle,
    Check,
    CheckCircle2,
    Edit2,
    Eye,
    EyeOff,
    FileText,
    Globe,
    Mail,
    Play,
    Power,
    Save,
    Server,
    Settings,
    Shield,
    X,
} from 'lucide-vue-next';
import { reactive, ref } from 'vue';

const props = defineProps<{
    configuration: any;
    templates: any;
    drivers: any;
    categories: any;
}>();

const { t } = useI18nStore();

const tabs = [
    { id: 'configuration', name: t('Configuration') },
    { id: 'templates', name: t('Email Templates') },
];

const activeTab = ref('configuration');
const showPassword = ref(false);
const showSesSecret = ref(false);
const showPostmarkToken = ref(false);
const testingConnection = ref(false);
const showSendTestDialog = ref(false);
const testEmail = ref('');
const sendingTest = ref(false);
const editingTemplate = ref(null);

const form = reactive({
    mail_driver: props.configuration.mail_driver,
    mail_from_address: props.configuration.mail_from_address,
    mail_from_name: props.configuration.mail_from_name,
    reply_to_email: props.configuration.reply_to_email,
    bcc_email: props.configuration.bcc_email,
    smtp_host: props.configuration.smtp_host,
    smtp_port: props.configuration.smtp_port,
    smtp_username: props.configuration.smtp_username,
    smtp_password: props.configuration.smtp_password_masked || '',
    smtp_encryption: props.configuration.smtp_encryption,
    ses_key: props.configuration.ses_key_masked || '',
    ses_secret: props.configuration.ses_secret_masked || '',
    ses_region: props.configuration.ses_region,
    postmark_token: props.configuration.postmark_token_masked || '',
    processing: false,
});

const templateForm = reactive({
    id: null,
    subject: '',
    html_content: '',
    plain_text_content: '',
    processing: false,
});

const saveConfiguration = () => {
    form.processing = true;
    router.post('/admin/settings/email/configuration', form, {
        preserveScroll: true,
        onFinish: () => {
            form.processing = false;
        },
    });
};

const testConnection = () => {
    testingConnection.value = true;
    router.post(
        '/admin/settings/email/test-connection',
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                testingConnection.value = false;
            },
        },
    );
};

const sendTest = () => {
    sendingTest.value = true;
    router.post(
        '/admin/settings/email/send-test',
        { email: testEmail.value },
        {
            preserveScroll: true,
            onFinish: () => {
                sendingTest.value = false;
                showSendTestDialog.value = false;
            },
        },
    );
};

const editTemplate = (template: any) => {
    editingTemplate.value = template;
    templateForm.id = template.id;
    templateForm.subject = template.subject;
    templateForm.html_content = template.html_content;
    templateForm.plain_text_content = template.plain_text_content || '';
};

const saveTemplate = () => {
    templateForm.processing = true;
    router.put(
        `/admin/settings/email/templates/${templateForm.id}`,
        templateForm,
        {
            preserveScroll: true,
            onFinish: () => {
                templateForm.processing = false;
                editingTemplate.value = null;
            },
        },
    );
};

const toggleTemplateStatus = (id: number) => {
    router.post(
        `/admin/settings/email/templates/${id}/toggle`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const sendTestTemplate = (template: any) => {
    const email = prompt(t('Enter email address to send test:'));
    if (email) {
        router.post(
            `/admin/settings/email/templates/${template.id}/send-test`,
            { email },
            {
                preserveScroll: true,
            },
        );
    }
};
</script>
