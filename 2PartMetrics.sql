#Задача 2. Расчитать среднее значение стоимости чека по странам.

#Создаём CTE, расчитывающее общую сумму чека на каждый заказ.
#Эти данные мы используем при расчёте среднего значения на страну.

with invoice_total as (
select invoice_no, country, sum(quantity * unit_price) as invoice_total from raw1
where quantity > 0
group by invoice_no, country
)


select country, round(avg(invoice_total), 2) as invoice_mean from invoice_total
group by country order by invoice_mean desc;

#Непосредственно расчитали среднее значение стоимости чека на страну с сортировкой по убыванию.

#Задача 3. Расчитать чистые доход и возвраты и коэффициент возвратов по странам.
#Чистым дохом назовём строку с положительным quantity, 
#чистым возвратом - строку с отрицательным quantity.
#Коэффициент возвратом определим как долю возвратов к общей выручке.

select country,
round(sum(quantity * unit_price) filter (where quantity > 0), 2) as country_gross,
coalesce(
round(sum(quantity * unit_price) filter (where quantity < 0), 2) * -1,
0) as country_return,
round(sum(quantity * unit_price), 2) as country_total,
coalesce(
(round(sum(quantity * unit_price) filter (where quantity < 0), 2) * -1) / nullif(round(sum(quantity * unit_price), 2), 0), 
0) as return_rate
from raw1 group by country order by return_rate desc;

#Задача 4. Вывести количество уникальных пользователей и связать это число с их первым 
#месяцем появления в системе. Посчитать матрицу Retention помесячно.

#Счёт месяцев мы ведём относительно первого встречающегося месяца в датасете и начиная от 0.

with month_0 as (
select distinct cust_id, 
min((extract (year from invoice_time) - 2010) * 12 + extract (month from invoice_time) - 12) as month_0 
from session_dynamic where cust_id != 'guest'
group by cust_id
),

cust_ret as (
select distinct sd.cust_id, sd.invoice_no, m.month_0,
(extract (year from invoice_time) - 2010) * 12 + extract (month from invoice_time) - 12 as invoice_month
from session_dynamic sd join month_0 m on sd.cust_id = m.cust_id
),

cohort_value as (
select month_0, count(distinct cust_id) as cohort_value from cust_ret
group by month_0
)

select cr.month_0, cv.cohort_value,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 0)) * 100
/
cv.cohort_value) as ret_0,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 1)) * 100 
/
cv.cohort_value) as ret_1,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 2)) * 100
/
cv.cohort_value) as ret_2,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 3)) * 100 
/
cv.cohort_value) as ret_3,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 4)) * 100
/
cv.cohort_value) as ret_4,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 5)) * 100 
/
cv.cohort_value) as ret_5,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 6)) * 100
/
cv.cohort_value) as ret_6,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 7)) * 100 
/
cv.cohort_value) as ret_7,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 8)) * 100
/
cv.cohort_value) as ret_8,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 9)) * 100 
/
cv.cohort_value) as ret_9,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 10)) * 100
/
cv.cohort_value) as ret_10,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 11)) * 100 
/
cv.cohort_value) as ret_11,
((count(distinct cr.cust_id) filter (where cr.invoice_month - cr.month_0 = 12)) * 100 
/
cv.cohort_value) as ret_12
from cust_ret cr join cohort_value cv on cr.month_0 = cv.month_0
group by cv.cohort_value, cr.month_0 order by month_0 asc;

#Заметим сразу одну аномалию: в 12 месяце (декабрь 2011) cohort_value держит сильно отстающий минимум.
#Объясняется это тем, что в датасете под 12 месяц выделено всего 9 дней истории. Итого это удельный на 9 
#месяцев показатель. Можно его аппроксимировать линейным образом: cohort_value(12) = 41 * 31/9 = 141, что всё ещё минимум.

#Гипотеза 1: регистрации колеблются квазипериодическим образом с максимумом зимой и минимумом летом.
#Гипотеза 2: интернет магазин скорее нацелен на возвращение старой аудитории, чем на приход новой 
#в периоды максимальной активности (предновогодние праздники - месяц 11).
#Гипотеза 3: из-за ограничений датасета в истории 0 месяц не является аномальным прибытком пользователей, но содержит в себе
#кор-аудиторию, которая присутствовала в магазине раньше периода датасета.

























