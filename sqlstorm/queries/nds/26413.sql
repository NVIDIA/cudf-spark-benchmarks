
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_location_type
    FROM 
        customer_address
),
DemographicsInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education_status,
        cd_purchase_estimate AS purchase_estimate
    FROM 
        customer_demographics
),
DateInfo AS (
    SELECT 
        d_date_sk,
        d_date,
        d_month_seq AS month_seq,
        d_year AS year,
        d_day_name AS day_name
    FROM 
        date_dim
    WHERE 
        d_year >= 2020
),
AggregatedSales AS (
    SELECT 
        ws_bill_cdemo_sk AS demo_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
FinalReport AS (
    SELECT 
        d.day_name,
        a.full_address,
        d.year,
        d.month_seq,
        de.gender,
        de.marital_status,
        de.education_status,
        de.purchase_estimate,
        ag.total_orders,
        ag.total_spent
    FROM 
        AddressInfo a 
        JOIN AggregatedSales ag ON a.ca_address_sk = ag.demo_sk
        JOIN DemographicsInfo de ON ag.demo_sk = de.cd_demo_sk
        JOIN DateInfo d ON d.d_date_sk = ag.demo_sk 
)
SELECT * 
FROM FinalReport
WHERE total_orders > 0
AND total_spent > 1000
ORDER BY year DESC, month_seq ASC, total_spent DESC
LIMIT 100;
