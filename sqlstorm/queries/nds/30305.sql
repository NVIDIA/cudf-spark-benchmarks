
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY ws_order_number) AS sale_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        MAX(cd.cd_purchase_estimate) AS highest_estimate
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(COALESCE(ws.ws_net_paid, 0)) > 500
), 
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS monthly_revenue
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), 
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.orders_count,
        ms.monthly_revenue
    FROM 
        customer_summary cs
    JOIN 
        monthly_sales ms ON EXTRACT(YEAR FROM DATE '2002-10-01') = ms.d_year
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(hv.total_spent, 0) AS total_spent,
    COALESCE(hv.orders_count, 0) AS orders_count,
    COALESCE(hv.monthly_revenue, 0) AS current_month_revenue
FROM 
    customer c
LEFT JOIN 
    high_value_customers hv ON c.c_customer_sk = hv.c_customer_sk
WHERE 
    c.c_birth_year IS NOT NULL
ORDER BY 
    total_spent DESC
LIMIT 10;
