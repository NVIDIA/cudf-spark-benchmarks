
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Top_Customers AS (
    SELECT 
        ccs.c_customer_sk,
        ccs.c_first_name,
        ccs.c_last_name,
        ccs.total_spent,
        RANK() OVER (ORDER BY ccs.total_spent DESC) AS sales_rank
    FROM 
        CTE_Customer_Sales ccs
)
SELECT 
    ctc.c_customer_sk,
    ctc.c_first_name,
    ctc.c_last_name,
    ctc.total_spent,
    CASE 
        WHEN ctc.sales_rank <= 10 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS customer_type,
    COALESCE(a.ca_city, 'Unknown') AS city,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_purchases
FROM 
    CTE_Top_Customers ctc
LEFT JOIN 
    customer_address a ON ctc.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON ctc.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY 
    ctc.c_customer_sk, ctc.c_first_name, ctc.c_last_name, ctc.total_spent, ctc.sales_rank, a.ca_city
ORDER BY 
    ctc.total_spent DESC;
