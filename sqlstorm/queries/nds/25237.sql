
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
        CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
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
        cd.cd_purchase_estimate
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
        DATE(d.d_date) AS sales_date,
        a.full_address,
        c.full_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        AddressInfo a ON ws.ws_ship_addr_sk = a.ca_address_sk
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    sales_date,
    full_name,
    full_address,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_sales_price) AS total_sales_generated,
    SUM(ws_net_profit) AS total_net_profit
FROM 
    SalesData
GROUP BY 
    sales_date, full_name, full_address
ORDER BY 
    sales_date DESC, total_net_profit DESC
LIMIT 100;
