<?php

/**
 * Copyright (c) 2013, EBANX Tecnologia da Informação Ltda.
 *  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of EBANX nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

require_once DIR_SYSTEM . 'library/ebanx-php/src/autoload.php';

/**
* The payment notifications controller
*/

class ControllerPaymentEbanxResponse extends Controller
{
	var $integrationKey;
	var $testMode;

	/**
	 * Initialize the EBANX settings before usage
	 * @return void
	 */
	protected function _setupEbanx()
	{
		if($this->config->get('ebanx_express_merchant_key') != null)
		{
			$this->integrationKey = $this->config->get('ebanx_express_merchant_key');
			$this->testMode = ($this->config->get('ebanx_express_mode') == 'test');
		}
		else if ($this->config->get('ebanx_express_boleto_merchant_key') != null)
		{
			$this->integrationKey = $this->config->get('ebanx_express_boleto_merchant_key');
			$this->testMode = ($this->config->get('ebanx_express_boleto_mode') == 'test');

		}else if ($this->config->get('ebanx_express_tef_merchant_key') != null){
			$this->integrationKey = $this->config->get('ebanx_express_tef_merchant_key');
			$this->testMode = ($this->config->get('ebanx_express_tef_mode') == 'test');

		}else {
			$this->integrationKey = $this->config->get('ebanx_merchant_key');
			$this->testMode = ($this->config->get('ebanx_mode') == 'test');
		}

		\Ebanx\Config::set(array(
		    'integrationKey' => $this->integrationKey
		  , 'testMode'       => $this->testMode
		  , 'directMode'     => true
		));
	}

	/**
	 * Save EBANX stuff to log
	 * @param  string $text Text to log
	 * @return void
	 */
	protected function _log($text)
	{
		return;
	}

	/**
	 * Notification action. It's called when a payment status is updated.
	 * @return void
	 */
	public function callback()
	{
		$view = array();
		$this->_setupEbanx();

		$this->language->load('payment/ebanx_express_tef');

		$view['title'] = sprintf($this->language->get('heading_title'), $this->config->get('config_name'));

		$view['base'] = $this->config->get('config_url');
		if (isset($this->request->server['HTTPS']) && ($this->request->server['HTTPS'] == 'on'))
		{
			$view['base'] = $this->config->get('config_ssl');
		}

		// Setup translations
		$view['language'] 		 = $this->language->get('code');
		$view['direction'] 		 = $this->language->get('direction');
		// $view['heading_title'] = sprintf($this->language->get('heading_title'), $this->config->get('config_name'));
		$view['text_response'] = $this->language->get('text_response');
		$view['text_success']  = $this->language->get('text_success');
		$view['text_failure']  = $this->language->get('text_failure');
		$view['text_success_wait'] = sprintf($this->language->get('text_success_wait'), $this->url->link('checkout/success'));
		$view['text_failure_wait'] = sprintf($this->language->get('text_failure_wait'), $this->url->link('checkout/checkout', '', 'SSL'));

		$hash = isset($this->request->get['hash']) ? $this->request->get['hash'] : false;
		if ($hash && strlen($hash))
		{
			$response = \Ebanx\Ebanx::doQuery(array('hash' => $hash));
			// Update the order status, then redirect to the success page
			if (isset($response->status) && $response->status == 'SUCCESS' && ($response->payment->status == 'PE' || $response->payment->status == 'CO'))
			{
				$order_status = 'ebanx_express_tef_order_status_';

				$this->load->model('checkout/order');
				// $order_id = str_replace('_', '', $response->payment->merchant_payment_code);
				$split = explode('-', $response->payment->merchant_payment_code);
				$order_id = current($split);
				$status_name = $response->payment->status;
				$status = $this->config->get($order_status . strtolower($status_name) . '_id');
				if ($this->isOpencart2())
				{
					$this->model_checkout_order->addOrderHistory($order_id, $status);
					// if (isset($this->session->data['order_id'])) {
					// 	$this->cart->clear();
					//
					// 	// Add to activity log
					// 	$this->load->model('account/activity');
					//
					// 	if ($this->customer->isLogged()) {
					// 		$activity_data = array(
					// 			'customer_id' => $this->customer->getId(),
					// 			'name'        => $this->customer->getFirstName() . ' ' . $this->customer->getLastName(),
					// 			'order_id'    => $this->session->data['order_id']
					// 		);
					//
					// 		$this->model_account_activity->addActivity('order_account', $activity_data);
					// 	} else {
					// 		$activity_data = array(
					// 			'name'     => $this->session->data['guest']['firstname'] . ' ' . $this->session->data['guest']['lastname'],
					// 			'order_id' => $this->session->data['order_id']
					// 		);
					//
					// 		$this->model_account_activity->addActivity('order_guest', $activity_data);
					// 	}
					//
					// 	unset($this->session->data['shipping_method']);
					// 	unset($this->session->data['shipping_methods']);
					// 	unset($this->session->data['payment_method']);
					// 	unset($this->session->data['payment_methods']);
					// 	unset($this->session->data['guest']);
					// 	unset($this->session->data['comment']);
					// 	unset($this->session->data['order_id']);
					// 	unset($this->session->data['coupon']);
					// 	unset($this->session->data['reward']);
					// 	unset($this->session->data['voucher']);
					// 	unset($this->session->data['vouchers']);
					// 	unset($this->session->data['totals']);
					// }
					$this->response->redirect($this->url->link('checkout/success'));
				}
				else
				{
					$this->model_checkout_order->update($order_id, $status);
				}

			}
			else
			{
				if ($this->isOpencart2())
				{
					$this->response->redirect($this->url->link('checkout/failure'));
				}
				else
				{
					$this->response->setOutput($this->render());
				}
			}
		}
		else
		{
			if ($this->isOpencart2())
			{
				$this->response->redirect($this->url->link('checkout/failure'));
			}
			else
			{
				$this->response->setOutput($this->render());
			}
		}


		// Render either for OC1 or OC2
		if ($this->isOpencart2())
		{
			$this->response->setOutput($this->load->view($template, $view));
		}
		else
		{
			$this->template = $template;
			$this->data     = $view;
			$this->response->setOutput($this->render());
		}
	}
	protected function isOpencart2()
	{
		return (intval(VERSION) >= 2);
	}
}
