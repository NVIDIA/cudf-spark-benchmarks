
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        c_customer_sk
),
combined_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit
    FROM 
        customer_summary cs
    LEFT JOIN 
        sales_summary ss ON cs.total_orders > 0
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    coalesce(cs.total_orders, 0) AS total_orders,
    coalesce(cs.total_spent, 0) AS total_spent,
    coalesce(cs.total_quantity, 0) AS quantity_purchased,
    coalesce(cs.total_sales, 0) AS sales_amount,
    coalesce(cs.total_profit, 0) AS profit_amount
FROM 
    customer c
LEFT JOIN 
    combined_summary cs ON c.c_customer_sk = cs.c_customer_sk
ORDER BY 
    total_spent DESC
LIMIT 100;
