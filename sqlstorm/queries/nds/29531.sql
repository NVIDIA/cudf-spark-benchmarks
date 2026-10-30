
WITH AddressConcat AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerFullName AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cdf.full_name, 
    asf.full_address, 
    ss.total_net_profit, 
    ss.total_orders
FROM 
    CustomerFullName cdf
JOIN 
    SalesSummary ss ON cdf.c_customer_sk = ss.ws_bill_customer_sk
JOIN 
    AddressConcat asf ON cdf.c_customer_sk = asf.ca_address_sk
WHERE 
    ss.total_net_profit > 1000
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
