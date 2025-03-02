# API для расчёта скидок и бонусов  

Этот API предназначен для расчёта стоимости покупок с учётом скидок, бонусов и уровней лояльности пользователей.  

## Как протестировать API  

### Способ 1: Postman
1. Запустить приложение:
```sh
bundle exec ruby app.rb
```
2. Открыть [Postman](https://www.postman.com/downloads/).  
3. Нажать **Import** → выбрать файл `test_requests.postman_collection.json`.
4. Открыть коллекцию **Test requests**.
5. Перейти к запросу **POST /operation**
6. Сменить адрес запроса на:
```sh
http://localhost:4567/operation
```
6. Отправить **запрос `/operation`** (расчет скидок и бонусов).  
7. Скопировать `operation_id` из ответа.
8. Перейти к запросу **POST /submit**
9. Сменить адрес запроса на:
```sh
http://localhost:4567/submit
```
10. Изменить `operation_id` в **теле запроса** и отправить его.

### Способ 2: cURL  
Запросы можно отправлять с помощью `curl` прямо из терминала. 
1. Запустить приложение:
```sh
bundle exec ruby app.rb
```
2. Пример запроса для **POST /operation**
```sh
curl -X POST http://localhost:4567/operation \
   -H "Content-Type: application/json" \
   -d '{
     "user_id": 1,
     "positions": [
       {"id": 1, "price": 100, "quantity": 2},
       {"id": 2, "price": 50, "quantity": 1},
       {"id": 3, "price": 170, "quantity": 5}
     ]
   }'
```
Пример ответа:
```sh
{"status":"success","user":{"id":1,"name":"Иван"},"operation_id":18,"sum":772.5,"bonus_information":{"bonus_balance":9304.031,"allowed_write_off":772.5,"cashback_percent":5.56,"will_be_charged":50.0},"discount_information":{"discount":127.5,"discount_percent":14.17},"positions":[{"type":"increased_cashback","amount":1,"description":"Молоко","product_discount_percent":0,"product_discount_value":0.0},{"type":"discount","amount":5,"description":"Хлеб","product_discount_percent":15,"product_discount_value":127.5}]}%   
```
3. Пример запроса для **POST /submit**
```sh
curl -X POST http://localhost:4567/confirm \
     -H "Content-Type: application/json" \
     -d '{
       "user": { "id": 1 },
       "operation_id": 18,
       "write_off": 700
     }'
```
Пример ответа:
```sh
{"status":"confirmed","message":"Операция успешно подтверждена","operation_info":{"user_id":1,"cashback_bonus":4.03,"cashback_percent":5.56,"total_discount":127.5,"discount_percent":14.17,"write_off":700.0,"final_sum_to_pay":72.5}}%     
```
