
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Sales_Statistics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        cs.avg_sales_price,
        DENSE_RANK() OVER (ORDER BY cs.total_net_profit DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Top_Customers AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_net_profit,
        s.total_orders,
        s.avg_sales_price
    FROM 
        Sales_Statistics s
    WHERE 
        s.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_net_profit, 0) AS net_profit,
    COALESCE(tc.total_orders, 0) AS orders_made,
    ROUND(tc.avg_sales_price, 2) AS average_sales_price,
    CASE 
        WHEN tc.total_net_profit IS NULL THEN 'No Sales'
        WHEN tc.total_net_profit < 5000 THEN 'Low Revenue'
        WHEN tc.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Revenue'
        ELSE 'High Revenue' 
    END AS revenue_category
FROM 
    Top_Customers tc
FULL OUTER JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    tc.total_orders IS NOT NULL 
    OR ca.ca_city IS NOT NULL
ORDER BY 
    net_profit DESC;
