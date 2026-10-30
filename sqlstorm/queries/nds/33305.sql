
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) as rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Monthly_Sales AS (
    SELECT 
        d_year, 
        d_month_seq, 
        d_date,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year, d_month_seq, d_date
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(NULLIF(ws_net_paid_inc_tax, 0)) AS avg_order_value,
        MAX(NULLIF(ws_net_paid_inc_tax, 0)) AS max_order_value
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    d.d_year, 
    d.d_month_seq, 
    ms.total_revenue,
    cs.total_orders,
    cs.avg_order_value,
    cs.max_order_value,
    SUM(CASE WHEN cs.total_orders > 0 THEN 1 ELSE 0 END) OVER() AS active_customers,
    SUM(CASE WHEN cs.total_orders > 0 THEN cs.total_orders ELSE 0 END) OVER () AS total_active_orders
FROM 
    Monthly_Sales AS ms
LEFT JOIN 
    Customer_Summary AS cs ON cs.total_orders > 0
JOIN 
    date_dim AS d ON ms.d_year = d.d_year
WHERE 
    d.d_year >= 2020 AND 
    ms.total_revenue IS NOT NULL
ORDER BY 
    d.d_year, d.d_month_seq;
