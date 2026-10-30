
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
),
ProcessedAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state) AS full_address
    FROM 
        customer_address ca
)
SELECT 
    cd.c_customer_id,
    cd.full_name,
    cd.first_purchase_date,
    cd.total_profit,
    pa.full_address
FROM 
    CustomerData cd
JOIN 
    ProcessedAddresses pa ON cd.c_customer_id = SUBSTRING(pa.full_address, LENGTH(pa.full_address) - 3, 4)
WHERE 
    cd.total_profit > 1000
ORDER BY 
    cd.total_profit DESC;
