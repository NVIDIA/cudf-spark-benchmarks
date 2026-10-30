
WITH  sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_manager,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_manager
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    s.s_store_name,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    d.total_quantity,
    d.total_profit,
    d.total_orders
FROM 
    sales_hierarchy s
JOIN 
    customer_info c ON c.purchase_rank <= 10 
LEFT JOIN 
    daily_sales d ON d.total_quantity IS NOT NULL 
WHERE 
    s.total_quantity > 1000 
    AND c.cd_gender = 'M' 
    AND (d.total_profit IS NULL OR d.total_profit > 5000)
ORDER BY 
    s.total_sales DESC;
