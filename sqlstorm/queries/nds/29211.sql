
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk, 
        d.d_year, 
        d.d_month_seq,
        d.d_day_name
    FROM 
        date_dim d
)

SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ad.full_address,
    ad.city_state_zip,
    ad.ca_country,
    di.d_year,
    di.d_month_seq,
    di.d_day_name,
    si.total_profit
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
JOIN 
    DateInfo di ON di.d_date_sk IN (SELECT DISTINCT ws.ws_sold_date_sk FROM web_sales ws)
JOIN 
    SalesInfo si ON si.ws_sold_date_sk = di.d_date_sk
WHERE 
    ci.cd_purchase_estimate > 10000
ORDER BY 
    si.total_profit DESC, ci.customer_name
LIMIT 100;
