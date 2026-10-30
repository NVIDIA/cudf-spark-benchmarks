
WITH  sales_data AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cs_item_sk
),
customer_metrics AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        AVG(ws_net_profit) AS avg_web_profit,
        SUM(CASE WHEN ws_net_paid_inc_tax IS NOT NULL THEN ws_net_paid_inc_tax ELSE 0 END) AS total_paid
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_sales AS (
    SELECT 
        s.ss_store_sk,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS revenue_rank
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY s.ss_store_sk
    HAVING SUM(ss_net_paid_inc_tax) > (SELECT AVG(ss_net_paid_inc_tax) FROM store_sales)
)
SELECT 
    cm.c_first_name, 
    cm.c_last_name, 
    cm.total_web_orders, 
    cm.avg_web_profit,
    COALESCE(sd.total_sales, 0) AS catalog_sales,
    COALESCE(ts.total_quantity_sold, 0) AS store_quantity_sold,
    ts.total_revenue
FROM customer_metrics cm
LEFT JOIN sales_data sd ON cm.total_web_orders = sd.sales_rank
LEFT JOIN top_sales ts ON cm.c_customer_sk = ts.ss_store_sk
WHERE 
    (cm.avg_web_profit IS NOT NULL AND cm.avg_web_profit > 0) OR 
    (ts.total_revenue IS NOT NULL AND ts.total_revenue < 1000)
ORDER BY 
    cm.total_web_orders DESC, 
    ts.total_revenue DESC;
