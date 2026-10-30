
WITH AddressDetails AS (
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    SUM(sd.ws_sales_price) AS total_sales_amount,
    SUM(sd.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
FROM 
    SalesData sd
JOIN 
    CustomerInfo ci ON sd.full_name = ci.full_name
GROUP BY 
    ci.full_name, 
    ci.ca_city, 
    ci.ca_state
HAVING 
    SUM(sd.ws_net_profit) > 1000
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
