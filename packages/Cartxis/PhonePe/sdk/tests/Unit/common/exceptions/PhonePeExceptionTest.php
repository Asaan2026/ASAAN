<?php

/*
*  Copyright (c) 2025 Original Author(s), PhonePe India Pvt. Ltd.
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*  http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*/

namespace Tests\Unit\common\exceptions;

use PhonePe\common\exceptions\PhonePeException;
use Tests\Fixtures\TestDataProvider;
use Tests\Unit\BaseTestCase;

class PhonePeExceptionTest extends BaseTestCase
{
    public function test_basic_exception_creation(): void
    {
        $message = TestDataProvider::TEST_ERROR_MESSAGE;
        $exception = new PhonePeException($message);

        $this->assertInstanceOf(PhonePeException::class, $exception);
        $this->assertEquals($message, $exception->getMessage());
        $this->assertEquals(0, $exception->getHttpStatusCode());
        $this->assertEquals(0, $exception->getCode());
        $this->assertNull($exception->getData());
    }

    public function test_exception_with_http_status_code(): void
    {
        $message = TestDataProvider::TEST_ERROR_MESSAGE;
        $httpStatus = 400;

        $exception = new PhonePeException($message, $httpStatus);

        $this->assertEquals($message, $exception->getMessage());
        $this->assertEquals($httpStatus, $exception->getHttpStatusCode());
        $this->assertEquals(0, $exception->getCode());
        $this->assertNull($exception->getData());
    }

    public function test_exception_with_all_parameters(): void
    {
        $message = TestDataProvider::TEST_ERROR_MESSAGE;
        $httpStatus = 400;
        $code = TestDataProvider::TEST_ERROR_CODE;
        $data = ['context' => 'test_error_context', 'field' => 'amount'];

        $exception = new PhonePeException($message, $httpStatus, $code, $data);

        $this->assertEquals($message, $exception->getMessage());
        $this->assertEquals($httpStatus, $exception->getHttpStatusCode());
        $this->assertEquals($code, $exception->getCode());
        $this->assertEquals($data, $exception->getData());
    }

    public function test_exception_with_previous_exception(): void
    {
        $message = TestDataProvider::TEST_ERROR_MESSAGE;
        $previous = new \Exception('Previous exception');

        $exception = new PhonePeException($message, 500, 'ERROR_500', null, $previous);

        $this->assertEquals($message, $exception->getMessage());
        $this->assertEquals(500, $exception->getHttpStatusCode());
        $this->assertEquals('ERROR_500', $exception->getCode());
        $this->assertSame($previous, $exception->getPrevious());
    }

    /**
     * @dataProvider httpErrorStatusProvider
     */
    public function test_exception_with_different_http_statuses(int $httpStatus, string $errorCode): void
    {
        $message = "HTTP Error: $httpStatus";
        $exception = new PhonePeException($message, $httpStatus, $errorCode);

        $this->assertEquals($message, $exception->getMessage());
        $this->assertEquals($httpStatus, $exception->getHttpStatusCode());
        $this->assertEquals($errorCode, $exception->getCode());
    }

    public static function httpErrorStatusProvider(): array
    {
        return TestDataProvider::httpErrorStatusProvider();
    }

    public function test_exception_with_complex_data(): void
    {
        $complexData = [
            'errors' => [
                ['field' => 'amount', 'code' => 'INVALID_AMOUNT', 'message' => 'Amount must be positive'],
                ['field' => 'merchantOrderId', 'code' => 'DUPLICATE_ORDER', 'message' => 'Order ID already exists'],
            ],
            'timestamp' => time(),
            'requestId' => 'req_123456789',
            'validationDetails' => [
                'minAmount' => 1,
                'maxAmount' => 999999999,
                'supportedCurrencies' => ['INR'],
            ],
        ];

        $exception = new PhonePeException('Validation failed', 400, 'VALIDATION_ERROR', $complexData);

        $this->assertEquals('Validation failed', $exception->getMessage());
        $this->assertEquals(400, $exception->getHttpStatusCode());
        $this->assertEquals('VALIDATION_ERROR', $exception->getCode());
        $this->assertEquals($complexData, $exception->getData());

        // Test specific data access
        $data = $exception->getData();
        $this->assertArrayHasKey('errors', $data);
        $this->assertCount(2, $data['errors']);
        $this->assertEquals('INVALID_AMOUNT', $data['errors'][0]['code']);
    }

    public function test_exception_inheritance(): void
    {
        $exception = new PhonePeException('Test exception');

        $this->assertInstanceOf(\Exception::class, $exception);
        $this->assertTrue(is_subclass_of($exception, \Exception::class));
    }

    public function test_exception_string_representation(): void
    {
        $message = 'Payment processing failed';
        $httpStatus = 422;
        $code = 'PAYMENT_FAILED';

        $exception = new PhonePeException($message, $httpStatus, $code);
        $stringRepresentation = (string) $exception;

        $this->assertStringContainsString($message, $stringRepresentation);
        $this->assertStringContainsString(__FILE__, $stringRepresentation);
    }

    public function test_exception_with_null_values(): void
    {
        $exception = new PhonePeException(null, null, null, null);

        $this->assertEmpty($exception->getMessage());
        $this->assertEquals(0, $exception->getHttpStatusCode());
        $this->assertEquals(0, $exception->getCode());
        $this->assertNull($exception->getData());
    }

    public function test_exception_with_empty_string_message(): void
    {
        $exception = new PhonePeException('');

        $this->assertEquals('', $exception->getMessage());
        $this->assertEquals(0, $exception->getHttpStatusCode());
    }

    public function test_exception_with_zero_http_status(): void
    {
        $exception = new PhonePeException('Test message', 0);

        $this->assertEquals('Test message', $exception->getMessage());
        $this->assertEquals(0, $exception->getHttpStatusCode());
    }

    public function test_exception_with_negative_http_status(): void
    {
        $exception = new PhonePeException('Test message', -1);

        $this->assertEquals('Test message', $exception->getMessage());
        $this->assertEquals(-1, $exception->getHttpStatusCode());
    }

    public function test_exception_data_immutability(): void
    {
        $originalData = ['key' => 'value', 'nested' => ['subkey' => 'subvalue']];
        $exception = new PhonePeException('Test', 400, 'ERROR', $originalData);

        $retrievedData = $exception->getData();

        // Modify the retrieved data
        $retrievedData['key'] = 'modified';
        $retrievedData['nested']['subkey'] = 'modified_sub';
        $retrievedData['new_key'] = 'new_value';

        // Original data in exception should remain unchanged
        $freshData = $exception->getData();
        $this->assertEquals('value', $freshData['key']);
        $this->assertEquals('subvalue', $freshData['nested']['subkey']);
        $this->assertArrayNotHasKey('new_key', $freshData);
    }

    public function test_exception_properties_are_public(): void
    {
        $exception = new PhonePeException('Test', 400, 'CODE', ['data' => 'test']);

        // Test that properties are accessible directly (based on the class implementation)
        $this->assertEquals(400, $exception->httpStatusCode);
        $this->assertEquals('Test', $exception->message);
        $this->assertEquals('CODE', $exception->code);
        $this->assertEquals(['data' => 'test'], $exception->data);
    }
}
