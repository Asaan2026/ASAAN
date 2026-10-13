<?php

namespace Cartxis\Core\Console\Commands;

use Cartxis\Core\Services\ExtensionService;
use Illuminate\Console\Command;

class ExtensionsActivateCommand extends Command
{
    protected $signature = 'cartxis:extensions:activate {code : Extension code}';

    protected $aliases = ['vortex:extensions:activate'];

    protected $description = 'Activate an installed extension.';

    public function handle(ExtensionService $extensions): int
    {
        $code = (string) $this->argument('code');

        try {
            $extension = $extensions->activate($code);
            $this->info("Activated: {$extension->code}");

            return self::SUCCESS;
        } catch (\Throwable $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
