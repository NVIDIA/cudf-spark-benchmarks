
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''))) AS full_address,
        ca_city AS city,
        ca_state AS state,
        ca_country AS country
    FROM 
        customer_address
),
CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        c_email_address AS email_address
    FROM 
        customer
),
SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    c.email_address,
    a.full_address,
    a.city,
    a.state,
    a.country,
    COALESCE(s.total_orders, 0) AS order_count,
    COALESCE(s.total_spent, 0) AS total_spent,
    COALESCE(s.avg_spent, 0) AS avg_spent
FROM 
    CustomerFullName c
LEFT JOIN 
    AddressParts a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesStatistics s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.state IN ('NY', 'CA') AND
    COALESCE(s.total_orders, 0) > 5
ORDER BY 
    total_spent DESC;
