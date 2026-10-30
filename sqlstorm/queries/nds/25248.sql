WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_street_number,
        CONCAT(ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city ILIKE '%Springfield%'
),

CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        wa.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
)

SELECT 
    cad.full_address,
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    sd.ws_order_number,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_sales_price) AS total_sales,
    SUM(sd.ws_net_profit) AS total_profit
FROM 
    CustomerAddressDetails cad
JOIN 
    CustomerInfo ci ON cad.ca_address_sk = ci.c_customer_sk 
JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_order_number 
GROUP BY 
    cad.full_address, ci.customer_name, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status, sd.ws_order_number
ORDER BY 
    total_profit DESC
LIMIT 10;