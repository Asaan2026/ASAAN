<?php

namespace Cartxis\Core\Console\Commands;

use Cartxis\Core\Services\ExtensionService;
use Illuminate\Console\Command;

class ExtensionsUninstallCommand extends Command
{
    protected $signature = 'cartxis:extensions:uninstall {code : Extension code}';

    protected $aliases = ['vortex:extensions:uninstall'];

    protected $description = 'Uninstall an extension.';

    public function handle(ExtensionService $extensions): int
    {
        $code = (string) $this->argument('code');

        try {
            $extensions->uninstall($code);
            $this->info("Uninstalled: {$code}");

            return self::SUCCESS;
        } catch (\Throwable $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
