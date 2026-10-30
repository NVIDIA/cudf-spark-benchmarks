
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
Top_Customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_web_sales,
        cs.total_orders,
        cs.avg_sales_price,
        cs.max_profit,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_web_sales,
    tc.total_orders,
    tc.avg_sales_price,
    tc.max_profit
FROM 
    Top_Customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_web_sales DESC;
