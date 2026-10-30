
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_sales_price) DESC) AS rank_sales
    FROM 
        catalog_sales AS cs
    JOIN 
        date_dim AS dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
customer_segments AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_demo_sk
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_fulfilled,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        warehouse AS w
    JOIN 
        web_sales AS ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    r.rank_sales,
    cs.unique_customers,
    cs.total_spent,
    ws.orders_fulfilled,
    ws.total_revenue
FROM 
    ranked_sales AS r
JOIN 
    customer_segments AS cs ON r.cs_item_sk = cs.cd_demo_sk
JOIN 
    warehouse_stats AS ws ON r.cs_item_sk = ws.w_warehouse_sk
WHERE 
    r.rank_sales <= 10
ORDER BY 
    r.rank_sales;
