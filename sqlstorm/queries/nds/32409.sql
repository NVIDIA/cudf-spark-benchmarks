
WITH  customer_sales AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
    HAVING 
        SUM(ws_ext_sales_price) > 0
),
sales_ranked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cs.total_sales >= 1000 THEN 'High Value'
            WHEN cs.total_sales >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.customer_value,
    sr.sales_rank,
    COALESCE(t.total_net_profit, 0) AS total_net_profit
FROM 
    high_value_customers hvc
LEFT JOIN 
    (SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit
     FROM 
        web_sales
     GROUP BY 
        ws_bill_customer_sk) t ON hvc.c_customer_sk = t.ws_bill_customer_sk
LEFT JOIN 
    sales_ranked sr ON hvc.c_customer_sk = sr.c_customer_sk
WHERE 
    hvc.customer_value = 'High Value'
ORDER BY 
    total_net_profit DESC, sales_rank;
