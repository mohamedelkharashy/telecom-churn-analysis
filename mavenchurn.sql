
--- over view 

select COUNT(*)  total_customers from telecom_customer_churn
select COUNT(*)  total_zipcodes  from telecom_zipcode_population
select TOP 10 * from telecom_customer_churn
select TOP 10 * from telecom_zipcode_population
---------------------------------------------------------------------
--- Customer status distribution

select customer_status, count(customer_id) total_customers
from telecom_customer_churn  
group by customer_status
order by total_customers
------------------------------------------------------------------------------
--- checking nulls

select
  sum(case when churn_reason is null then 1 else 0 end) nnull_churn_reason,
  sum(case when internet_type is null then 1 else 0 end) null_internet_type,
  sum(case when offer is null then 1 else 0 end)        null_offer
  from telecom_customer_churn
-------------------------------------------------------------------------------
--- all churn reason nulls should belong to non-churned customers

select count(*)
from telecom_customer_churn
where Customer_Status = 'Churned' AND [Churn_Reason] IS NULL
--------------------------------------------------------------------------------
--- duplicate check

select customer_id, count(*) 
from telecom_customer_churn
group by customer_id
having count(*) > 1
---------------------------------------------------------------------------------
--- create clean view for power BI

create view clean_churn_data as
select 
customer_id, 
city,
zip_code,
gender,
age,
married,
[contract],
payment_method,
monthly_charge,
total_charges,
total_revenue,
tenure_in_months,
customer_status,
churn_reason,
isnull (internet_type,'no internet') internet_type,
isnull (offer, 'no offer') offer,
case 
  when tenure_in_months <= 6 then '0-6 months'
  when tenure_in_months <= 12 then '6-12 months'
  when tenure_in_months <= 24 then '12-24 months'
  else '24+ months'
  End tenure_categores
  from telecom_customer_churn
-------------------------------------------------------------------------------------
---churn rate 

select
round(100.0*sum(case when customer_status ='churned' then 1 else 0 end)/count(*),1) churn_rate
from clean_churn_data
where customer_status != 'joined'
------------------------------------------------------------------------------------------------------------
 ---churn rate by contract type

  select 
    [Contract],
    count(*) total,
    sum(case when customer_status= 'churned' then 1 else 0 end) as total_churned,
    round(100.0*sum(case when customer_status = 'churned' then 1 else 0 end)/ count(*), 1) as churn_rate
    from clean_churn_data
    where customer_status != 'joined'
    group by [Contract]
 ------------------------------------------------------------------------------------------------------------
 ---churn rate by churn reason

 select
    Churn_Reason,
    count(*) as total_churned,
    round (100.0 * count(*)/ (select count(*) from clean_churn_data where customer_Status = 'churned'),1) churn_rate 
    from clean_churn_data
where customer_Status ='churned'
group by churn_Reason
order by churn_rate desc      
------------------------------------------------------------------------------------------------------------------------------------------
--- churn rate by contract vs overall churn
with contract_churn_vs_overall_churn as (
    select
        [Contract],
        count(*) as total,
        sum(case when customer_status = 'Churned' then 1 else 0 end) as churned
    from clean_churn_data
    where customer_status != 'joined'
    group by [Contract] )

select
    [Contract],
    total,
    churned,
    round(100.0 * churned / total, 1) AS churn_rate,
    round(100.0 * sum(churned) over()/ sum(total) over(), 1) as overall_churn_rate
    from contract_churn_vs_overall_churn
    order by churn_rate desc
-----------------------------------------------------------------------------------------------------------------------------
 ---churn rate by internet type
 select 
    internet_type,
    count(*) total,
    sum(case when customer_status= 'churned' then 1 else 0 end) as total_churned,
    round(100.0*sum(case when customer_status = 'churned' then 1 else 0 end)/ count(*), 1) as churn_rate
    from clean_churn_data
    where customer_status != 'joined'
    group by internet_type 
    order by churn_rate desc