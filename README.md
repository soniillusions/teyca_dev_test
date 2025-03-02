# API для расчёта скидок и бонусов  

Этот API предназначен для расчёта стоимости покупок с учётом скидок, бонусов и уровней лояльности пользователей.  

## Как протестировать API  

### 1. Postman
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

### 2. cURL  
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
     "user_id": 2,
     "positions": [
       {"id": 1, "price": 100, "quantity": 2},
       {"id": 2, "price": 50, "quantity": 1},
       {"id": 3, "price": 170, "quantity": 5}
     ]
   }'
```
Пример ответа:
```sh
{
  "status": "success",
  "user": {
    "id": 2,
    "name": "Марина"
  },
  "operation_id": 28,
  "sum": 727.5,
  "bonus_information": {
    "bonus_balance": 9301.53,
    "allowed_write_off": 727.5,
    "cashback_percent": 5.56,
    "will_be_charged": 50.0
  },
  "discount_information": {
    "discount": 172.5,
    "discount_percent": 19.17
  },
  "positions": [
    {
      "type": "increased_cashback",
      "amount": 1,
      "description": "Молоко",
      "product_discount_percent": 5,
      "product_discount_value": 2.5
    },
    {
      "type": "discount",
      "amount": 5,
      "description": "Хлеб",
      "product_discount_percent": 20,
      "product_discount_value": 172.5
    }
  ]
}%  
```
3. Пример запроса для **POST /submit**
```sh
curl -X POST http://localhost:4567/submit \
     -H "Content-Type: application/json" \
     -d '{
       "user": { "id": 2 },
       "operation_id": 28,
       "write_off": 700
     }'
```
Пример ответа:
```sh
{
  "status": "confirmed",
  "message": "Операция успешно подтверждена",
  "operation_info": {
    "user_id": 2,
    "cashback_bonus": 1.53,
    "cashback_percent": 5.56,
    "total_discount": 172.5,
    "discount_percent": 19.17,
    "write_off": 700.0,
    "final_sum_to_pay": 27.5
  }
}%   
```
