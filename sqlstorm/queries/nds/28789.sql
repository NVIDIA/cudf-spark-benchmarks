
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_day_name
    FROM date_dim d
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk AS date_key,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk
),
AggregatedSales AS (
    SELECT 
        di.d_year,
        di.d_month_seq,
        SUM(sd.total_sales) AS monthly_sales,
        SUM(sd.total_orders) AS monthly_orders
    FROM DateInfo di
    JOIN SalesData sd ON di.d_date_sk = sd.date_key
    GROUP BY di.d_year, di.d_month_seq
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.ca_zip,
    asales.monthly_sales,
    asales.monthly_orders,
    CASE 
        WHEN asales.monthly_sales IS NULL THEN 'No Sales'
        WHEN asales.monthly_sales > 10000 THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_category,
    COUNT(DISTINCT di.d_date) AS active_days
FROM CustomerInfo ci
LEFT JOIN AggregatedSales asales ON ci.c_customer_sk = asales.d_year
LEFT JOIN DateInfo di ON di.d_year = asales.d_year AND di.d_month_seq = asales.d_month_seq
GROUP BY ci.full_name, ci.ca_city, ci.ca_state, ci.ca_country, ci.ca_zip, asales.monthly_sales, asales.monthly_orders
ORDER BY asales.monthly_sales DESC;
