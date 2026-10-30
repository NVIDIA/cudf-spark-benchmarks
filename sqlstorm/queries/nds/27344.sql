
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        d.d_date AS birthday
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_date AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
GenderSales AS (
    SELECT 
        ci.cd_gender,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(sd.ws_order_number) AS total_orders
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
    GROUP BY 
        ci.cd_gender
),
MaritalStatusSales AS (
    SELECT 
        ci.cd_marital_status,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(sd.ws_order_number) AS total_orders
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
    GROUP BY 
        ci.cd_marital_status
)
SELECT 
    gs.cd_gender,
    gs.total_profit AS gender_profit,
    gs.total_orders AS gender_orders,
    ms.cd_marital_status,
    ms.total_profit AS marital_profit,
    ms.total_orders AS marital_orders
FROM 
    GenderSales gs
JOIN 
    MaritalStatusSales ms ON gs.cd_gender = ms.cd_marital_status
ORDER BY 
    gender_profit DESC, marital_profit DESC;
