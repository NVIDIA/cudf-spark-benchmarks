
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_monthly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
store_performance AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        store s
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    cs.total_orders,
    cs.total_spent,
    mp.total_monthly_sales AS monthly_average_sales,
    sp.total_orders AS store_orders,
    sp.total_profit
FROM 
    customer_stats cs
LEFT JOIN 
    (SELECT 
        d_year, 
        AVG(total_monthly_sales) AS total_monthly_sales 
     FROM 
        monthly_sales 
     GROUP BY 
        d_year) mp ON cs.total_orders > 0
LEFT JOIN 
    store_performance sp ON cs.total_orders < sp.total_orders
WHERE 
    cs.total_spent IS NOT NULL
    AND cs.total_orders > 5
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
