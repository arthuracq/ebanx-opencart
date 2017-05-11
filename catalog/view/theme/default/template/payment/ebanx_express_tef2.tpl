<style>
ul.payment-methods {
  list-style: none;
  overflow: hidden;
  padding-left: 0 !important;
}
ul.payment-methods li {
  float: left;
  margin: 0 10px 0 0;
  overflow: hidden;
}
ul.payment-methods li input {
  float: left;
  margin: 0 !important;
  display: none;
}
ul.payment-methods li label {
  float: left;
}
ul.payment-methods li label img {
  opacity: 1;
}

ul.ebanx-tef-info {
  list-style: none;
  overflow: hidden;
  padding-left: 0 !important;
}
ul.ebanx-tef-info li input {
  float: left;
  margin: 0 !important;
  display: none;
}
ul.ebanx-tef-info li label {
  float: left;
}
ul.ebanx-tef-info li label img {
  opacity: 1;
}
ul.ebanx-tef-info li label img:hover,
ul.ebanx-tef-info li label img.active {
  opacity: 0.5;
}



.ebanx-cc-info {
  display: none;
}

.ebanx-tef-info {
  display: none;
}

#ebanx-error {
  display: none;
}

.tef {
  display: none;
}
#button-confirm {
  cursor: pointer;
}
</style>


<div class="alert alert-danger" id="ebanx-error">
</div>

<div class="form-group required">
<form method="post" id="payment">
  <!--<?php //if ($enable_installments): ?>-->
    <h2><?php echo $entry_ebanx_details ?></h2>
    <div class="content" id="payment">
      <table class="form">
        <tbody>
          <tr>
            <td>CPF</td>
            <td><input type="text" size="14" name="ebanx[cpf]" id="ebanx_cpf" value="<?php echo $ebanx_cpf ?>" /></td>
          </tr>

          <tr>
            <td><?php echo $entry_dob ?></td>
            <td><input type="text" size="10" name="ebanx[dob]" id="ebanx_dob" value="<?php echo $ebanx_dob ?>" /></td>
          </tr>

          <tr class="ebanx-tef-info">
            <td><?php echo $entry_tef_details ?> </td>
            <td>
              <select id="ebanx_tef_type" name="ebanx[tef_type]" autocomplete="off">
                <option value="" selected="selected"><?php echo $entry_please_select ?></option>
                <option value="bancodobrasil">Banco do Brasil</option>
                <option value="banrisul">Banrisul</option>
                <option value="bradesco">Bradesco</option>
                <option value="itau">Itaú</option>

              </select>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  <!--<?php //endif ?>-->

  <div class="buttons">
    <div class="right">
      <img src="image/ebanx/ebanx-checkout.png" id="button-confirm" />
    </div>
  </div>
</form>
</div>

<script>
    /**
     * Hack to show installments interest in the totals
     * @return {void}
     */
    var updateTotals = function() {
      var total    = '<?php echo $total_view ?>'
        , interest = '<?php echo $interest_view ?>'
        , totalWithInterest = '<?php echo $totalWithInterest ?>';

      if (interest.replace(/\D/, '') == '0') {
        return;
      }

      var installments = $('#ebanx_installments_number');

      if ($(installments && installments.val() > 1)) {
        if (!$('#ebanx-discount').length) {
          var interestHtml = '<tr id="ebanx-discount"><td colspan="4" class="price"><b><?php echo $entry_interest ?>:</b></td><td class="total">' + interest + '</td></tr>';
          $(interestHtml).insertBefore($('.checkout-product tfoot tr:last-child'));
          $('.checkout-product tfoot tr:last-child').children('td:last-child').html(totalWithInterest);
        }
      } else {
        $('#ebanx-discount').remove();
        $('.checkout-product tfoot tr:last-child').children('td:last-child').html(total);
      }
    };

    $('#ebanx_installments_number').change(updateTotals);

    /**
     * Shows an error message and focuses on the element with errors
     * @param  {string} message The error message
     * @param  {selector} elm   The selector of the element
     * @return {boolean}
     */
    var showError = function(message, elm) {
      $('#ebanx-error').text(message).show();

      if (elm) {
        elm.focus();
      }

      return false;
    };

    /**
     * Hides the error message and clears its text
     * @return {[type]} [description]
     */
    var hideError = function() {
      $('#ebanx-error').text('').hide();
    };

    /**
     * Validates the CPF number
     * @param  {string} cpf The CPF number
     * @return {boolean}
     */
    var validCpf = function(cpf) {
      // Allows only numbers, dots and dashes
      if (cpf.match(/[a-z]/gi)) {
        return false;
      }

      var digits = cpf.replace(/[\D]/g, '')
        , dv1, dv2, sum, mod;

      if (digits.length == 11) {
        d = digits.split('');

        sum = d[0] * 10 + d[1] * 9 + d[2] * 8 + d[3] * 7 + d[4] * 6 + d[5] * 5 + d[6] * 4 + d[7] * 3 + d[8] * 2;
        mod = sum % 11;
        dv1 = (11 - mod < 10 ? 11 - mod : 0);

        sum = d[0] * 11 + d[1] * 10 + d[2] * 9 + d[3] * 8 + d[4] * 7 + d[5] * 6 + d[6] * 5 + d[7] * 4 + d[8] * 3 + dv1 * 2;
        mod = sum % 11;
        dv2 = (11 - mod < 10 ? 11 - mod : 0);

        return dv1 == d[9] && dv2 == d[10];
      }

      return false;
    };

    /**
     * Validates the credit card number using the Luhn algorithm
     * @param  {string} value The credit card number
     * @return {boolean}
     */
    var validCreditCard = function(value) {
      // Non numeric characters are not allowed
      if (value.match(/\D/)) {
        return false;
      }

      value = value.replace(/\D/g, '');

      var nCheck = 0
        , nDigit = 0
        , bEven  = false;

      for (var n = value.length - 1; n >= 0; n--) {
        var cDigit = value.charAt(n)
          , nDigit = parseInt(cDigit, 10);

        if (bEven) {
          if ((nDigit *= 2) > 9) {
            nDigit -= 9;
          }
        }

        nCheck += nDigit;
        bEven  = !bEven;
      }

      return (nCheck % 10) == 0 && nCheck > 0;
    };

    /**
     * Validates the EBANX input fields
     * @return {boolean}
     */
    var validateEbanx = function() {
      hideError();

      var cpf = $('#ebanx_cpf')
        , dob = $('#ebanx_dob');

      if (!validCpf(cpf.val())) {
        return showError('CPF is invalid.', cpf);
      }

      if (dob.val().length != 10) {
        return showError('Date of Birth is invalid.', dob);
      }

      return true;
    };


    /**
     * Binds the click event to the confirmation button. Applies validation to
     * input fields.
     * @param  {event} e
     * @return {void}
     */
    $('#button-confirm').bind('click', function(e) {
      e.preventDefault();

      if (validateEbanx() == false) {
        return;
      }

      $.ajax({
          url: 'index.php?route=payment/ebanx_express_tef/checkoutDirect'
        , type: 'post'
        , data: $('#payment select, #payment input[type=text], #payment input[type=radio]:checked')
        , beforeSend: function() {
            $('#payment .warning').remove();
            $('#button-confirm').fadeToggle();
            $('#payment').before('<div class="attention"><img src="catalog/view/theme/default/image/loading.gif" alt="" /></div>');
          }
        , complete: function() {
            $('#button-confirm').fadeToggle();
            $('#payment').parent().find('.attention').remove();
          }
        , success: function(response) {
            // If the response is a URL, redirect to it
            if (response.match(/^http/)) {
              window.location = response;
            // Otherwise display an error message
            } else {
              $('.buttons').before('<div class="alert alert-danger warning">' + response + '</div>');
              $('#payment .attention').remove();
            }
          }
      });
    });

    $('#ebanx_dob').datetimepicker({
        format: 'DD/MM/YYYY'
      , changeMonth: true
      , changeYear: true
      , yearRange: '<?php echo date('Y') - 100 ?>:<?php echo date('Y') - 16 ?>'
    });

    /**
     * Show/hide credit card fields
     * @return {[type]} [description]
     */
     $('.ebanx-tef-info').show();
     updateTotals();

    /**
     * Toggles the payment method image active
     * @return {void}
     */
    $('ul.payment-methods li img').click(function() {
      var self = $(this);

      $('ul.payment-methods li img').removeClass('active');
      self.addClass('active');
    });

    $('ul.ebanx-tef-info li img').click(function() {
      var self = $(this);

      $('ul.ebanx-tef-info li img').removeClass('active');
      self.addClass('active');
    });
</script>
