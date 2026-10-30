
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicsInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
DateInfo AS (
    SELECT 
        d_date_id,
        d_date,
        d_year,
        d_month_seq,
        d_day_name
    FROM 
        date_dim
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    A.full_address, 
    A.ca_city, 
    A.ca_state, 
    D.d_year, 
    D.d_month_seq, 
    D.d_day_name, 
    SUM(S.total_sales) AS total_sales_amount, 
    COUNT(DISTINCT S.ws_item_sk) AS item_count,
    COUNT(DISTINCT D.d_date_id) AS active_dates
FROM 
    AddressInfo A
JOIN 
    DemographicsInfo CD ON A.ca_address_sk = CD.cd_demo_sk 
JOIN 
    DateInfo D ON D.d_year = 2022 
JOIN 
    SalesInfo S ON S.ws_item_sk = CD.cd_demo_sk
GROUP BY 
    A.full_address, 
    A.ca_city, 
    A.ca_state, 
    D.d_year, 
    D.d_month_seq, 
    D.d_day_name
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
