#Задача 1: очистить данные от строк, которые бы портили количественные значения метрик.
#Создать таблицу, отражающую динамику действий пользователей.

#1

select description, count(*) from raw1 group by description order by description;
#Структурная гипотеза: desciption не принимает null-значений, 
#пустые строки description - мусорные данные.

select * from raw1 where description = '';
#Пустая строка description означает внутрисистемные операции по пересчёту количества товара,
#т.к. у этих операций нет айди клиента и выплаченной суммы.

delete from raw1 where description = '';
#Итого: удаляем мусорные данные, которые в себе не несут никакой информации.

#2

select * from raw1 where unit_price = 0 order by quantity asc;
#Структурная гипотеза: нулевая цена сопутствует двум категориям потока: мусорные внутрисистемные операции,
#крупные подарки оптовым/конкретным заказчикам. Первая категория будет мусорной и подлежит удалению,
#вторую важно также учесть в расчётах прибыльности регионов/товаров или расчётах логистической активности региона. 

select description, sum(quantity) from raw1
where unit_price = 0 and (description ~ '[a-z]' and description not like '%cm' and description not like '%No')
or description like '%?%'
group by description order by sum(quantity) desc;
#Отделяем мусор от реального потока. Предположение: мусор незарегистрирован.
#Полученную фильтрацию применяем для удаления.

select description, sum(quantity) from raw1 where unit_price = 0 and cust_id is not null 
group by description order by sum(quantity) desc;
#Среди зарегистрированных пользователей данные указывают на реальный поток, который 
#необходимо учитывать в логистической активности региона.

delete from raw1 
where  description ~ '[a-z]' and description not like '%cm' and 
description not like '%No' or description like '%?%';

delete from raw1 where unit_price = 0 and quantity < 0;
#Итого: удаляем мусорные данные, которые в себе не несут никакой информации. Остаток грязи играет роль малого шума.

#3

create table session_dynamic as with a as (
select coalesce(cust_id::text, 'guest') as cust_id, to_timestamp(invoice_date, 'MM/DD/YYYY HH24:MI') as invoice_time, country, invoice_no from raw1)
select * from a;
#Вводим новую таблицу, с логами действий, которая отражает динамику зарегистрированных пользователей: 
#время совершенствования действия (покупки), номер чека заказа. Незарегистрированных пользователей
#отмечаем как гостей

select * from session_dynamic;

select invoice_no, count(distinct cust_id) from session_dynamic
group by invoice_no order by count(distinct cust_id) asc;
#Совершаем проверку на наличие аномалий: необходимо инъективное соответствие
#invoice_no к cust_id в смысле множества. Видим, что такого рода аномалий нет.
#Нет также и пересечений между категорией guest и авторизированными пользователями.



