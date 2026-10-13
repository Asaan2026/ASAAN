<?php

namespace Cartxis\Core\Console\Commands;

use Cartxis\Core\Services\ExtensionService;
use Illuminate\Console\Command;

class ExtensionsDeactivateCommand extends Command
{
    protected $signature = 'cartxis:extensions:deactivate {code : Extension code}';

    protected $aliases = ['vortex:extensions:deactivate'];

    protected $description = 'Deactivate an active extension.';

    public function handle(ExtensionService $extensions): int
    {
        $code = (string) $this->argument('code');

        try {
            $extension = $extensions->deactivate($code);
            $this->info("Deactivated: {$extension->code}");

            return self::SUCCESS;
        } catch (\Throwable $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
