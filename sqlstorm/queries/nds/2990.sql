
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),

AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        RankedSales
    WHERE 
        rnk <= 10
    GROUP BY 
        ws_item_sk
),

CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)

SELECT 
    ca.ca_city,
    COALESCE(SUM(ag.total_sales), 0) AS total_sales_from_city,
    COUNT(DISTINCT co.c_customer_sk) AS total_customers,
    AVG(co.total_spent) AS avg_spent_per_customer,
    MAX(co.total_spent) AS max_spent_by_customer
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    AggregateSales ag ON ag.ws_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk
    )
LEFT JOIN 
    CustomerOrders co ON c.c_customer_sk = co.c_customer_sk
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT co.c_customer_sk) > 0
ORDER BY 
    total_sales_from_city DESC;
