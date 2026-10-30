
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ws.ws_ext_sales_price), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_sales,
        cs.sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 10
),
sales_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(ws.ws_order_number) AS number_of_orders,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    sd.total_quantity,
    sd.number_of_orders,
    sd.total_profit,
    CASE 
        WHEN sd.total_profit IS NULL OR sd.total_profit < 0 THEN 'Loss'
        WHEN sd.total_profit = 0 THEN 'Breakeven'
        ELSE 'Profit'
    END AS profit_status
FROM 
    top_customers tc
JOIN 
    sales_details sd ON tc.c_customer_sk = sd.c_customer_sk
ORDER BY 
    tc.total_sales DESC;
