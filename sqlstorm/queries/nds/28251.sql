
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_location_type
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date_sk,
        CAST(d_date AS STRING) AS formatted_date,
        d_month_seq,
        d_week_seq,
        d_year,
        d_day_name
    FROM date_dim
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ship_mode_sk,
        ws.ws_net_profit,
        sm.sm_code AS shipping_method
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
AggregatedSales AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        dd.formatted_date,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit,
        ARRAY_AGG(DISTINCT sd.shipping_method) AS shipping_methods
    FROM CustomerDetails cd
    JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    JOIN SalesDetails sd ON cd.c_customer_sk = sd.ws_order_number
    JOIN DateDetails dd ON sd.ws_order_number = dd.d_date_sk
    GROUP BY 
        cd.full_name, 
        ad.full_address, 
        dd.formatted_date
)
SELECT 
    full_name,
    full_address,
    formatted_date,
    total_quantity,
    total_profit,
    shipping_methods
FROM AggregatedSales
WHERE total_profit > 1000
ORDER BY total_profit DESC;
