document.addEventListener('DOMContentLoaded', function() {
  var html = document.getElementsByTagName('html')[0];
  if(html.className != 'dashboard-controller show-action') {
    return;
  }

  var creditCardForm = document.getElementById('credit-card');
  var stripe = Stripe(creditCardForm.getAttribute('api-key'));
  var elements = stripe.elements();
  var creditCard = elements.create('card');
  var hasCreditCard = creditCardForm.getAttribute('data-found') === 'true';

  var api = {
    query: function(params) {
      var queryString = [];
      for(var key in params) {
        if(params.hasOwnProperty(key)) {
          queryString.push(encodeURIComponent(key) + "=" + encodeURIComponent(params[key]))
        }
      }
      return queryString.join('&');
    },
    get: function(path, params) {
      if(params) {
        path = path + '?' + api.query(params);
      }
      return api.request('get', path);
    },
    post: function(path, params) {
      return api.request('post', path, params);
    },
    put: function(path, params) {
      return api.request('put', path, params);
    },
    delete: function(path, params) {
      return api.request('delete', path, params);
    },
    request: function(method, path, params) {
      var opts = {
        method: method.toUpperCase(),
        credentials: 'same-origin',
        headers: {},
      };

      if(method != 'get' && params) {
        opts.body = JSON.stringify(params);
        opts.headers['Content-Type'] = 'application/json';
      };

      return fetch(path, opts).then(function(response) {
        return response.json();
      });
    },
  };

  var dashboard = new Vue({
    el: '#dashboard',
    data: {
      currentTab: 'remits',
      currentRimitTab: 'sent',
      amount: 0,
      charge_amount: 0,
      charges: [],
      recvRemits: [],
      sentRemits: [],
      hasCreditCard: hasCreditCard,
      isActiveNewRemitForm: false,
      isActiveChargeConfirmDialog: false,
      isActiveDeleteCreditCard: false,
      target: "",
      register_notification: "",
      register_error_messages: "",
      creditCard: {
        brand: "",
        last4: "",
      },
      user: {
        email: "",
        nickname: "",
      },
      newRemitRequest: {
        emails: [],
        amount: 0,
      },
    },
    beforeMount: function() {
      var self = this;
      api.get('/api/user').then(function(json) {
        self.user = json;
      });

      api.get('/api/charges').then(function(json) {
        self.amount = json.amount;
        self.charges = json.charges;
      });

      api.get('/api/credit_card').then(function(json) {
        self.creditCard.brand = json.brand;
        self.creditCard.last4 = json.last4;
      });

      api.get('/api/remit_requests', { status: 'outstanding' }).
        then(function(json) {
          self.sentRemits = json.sent;
          self.recvRemits = json.request;
        });

      setInterval(function() {
        api.get('/api/remit_requests', { status: 'outstanding' }).
          then(function(json) {
            self.sentRemits = json.sent;
            self.recvRemits = json.request;
          });
      }, 5000);
    },
    mounted: function() {
      var form = document.getElementById('credit-card');
      if(form){ creditCard.mount(form); }
    },
    methods: {
      show_register_notification: function(json){
        if(json.errors){
          this.register_notification = "更新に失敗しました。"
            this.register_error_messages += json.errors;
        }else{
          this.register_notification = "更新しました。"
        }
      },
      show_charge_modal: function(amount) {
        if(hasCreditCard) {
          this.charge_amount = amount;
          this.isActiveChargeConfirmDialog = true;
        }
      },
      show_card_delete_modal: function(amount) {
        if(hasCreditCard) {
          this.isActiveDeleteCreditCard = true;
        }
      },
      charge: function(amount, event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.post('/api/charges', { amount: amount }).
          then(function(json) {
            self.amount += amount;
            self.charges.unshift(json);
          }).
          catch(function(err) {
            console.error(err);
          });
      },
      registerCreditCard: function(event) {
        if(event) { event.preventDefault(); }

        var self = this;
        stripe.createToken(creditCard).
          then(function(result) {
            return api.post('/api/credit_card', { credit_card: { source: result.token.id }});
          }).
          then(function(json) {
            self.creditCard.brand = json.brand;
            self.creditCard.last4 = json.last4;
            self.hasCreditCard = true;
          });
      },

      addTarget: function(event) {
        if(event) { event.preventDefault(); }
        var self = this;
        api.post('/api/user_emails', { email: this.target} ).
            then(function (json) {
              if(json.error == 'Not found'){
                alert("そのメールアドレスは登録されていません");
              }else{
                if(!self.newRemitRequest.emails.includes(self.target)){
                  self.newRemitRequest.emails.push(self.target);
                }
              }
        })
      },
      removeTarget: function(email, event) {
        if(event) { event.preventDefault(); }

        this.newRemitRequest.emails = this.newRemitRequest.emails.filter(function(e) {
          return e != email;
        });
      },
      sendRemitRequest: function(event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.post('/api/remit_requests', this.newRemitRequest).
          then(function() {
            self.newRemitRequest = {
              emails: [],
              amount: 0,
            };
            self.target = '';
            self.isActiveNewRemitForm = false;
          });
      },
      accept: function(id, event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.post('/api/remit_requests/' + id + '/accept').
          then(function() {
            self.recvRemits = self.recvRemits.filter(function(r) {
              if(r.id != id) {
                return true
              } else {
                self.amount -= r.amount;
                return false
              }
            });
          });
      },
      reject: function(id, event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.post('/api/remit_requests/' + id + '/reject').
          then(function() {
            self.recvRemits = self.recvRemits.filter(function(r) {
              return r.id != id;
            });
          });
      },
      updateUserNickname: function(event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.put('/api/user?attribute=nickname', { user: this.user }).
          then(function(json) {
            self.show_register_notification(json);
            self.user = json;
          });
      },
      updateUserEmail: function(event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.put('/api/user?attribute=email', { user: this.user }).
          then(function(json) {
            self.show_register_notification(json);
            self.user = json;
          });
      },
       updateUserPassword: function(event) {
        if(event) { event.preventDefault(); }

        var self = this;
        api.put('/api/user?attribute=password', { user: this.user }).
          then(function(json) {
            self.show_register_notification(json);
            self.user = json;
          });
      },
      removeCreditCard: function(event){
        if(event) { event.preventDefault(); }
        var self = this;
        api.delete('/api/credit_card').
        then(function() {
          self.creditCard.brand = null;
          self.creditCard.last4 = null;
          self.hasCreditCard = false;
        })
      }
    }
  });
});
