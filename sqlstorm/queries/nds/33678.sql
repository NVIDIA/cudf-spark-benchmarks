
WITH  sales_cte AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 365 FROM date_dim)
    GROUP BY 
        ss_store_sk, ss_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        w.w_warehouse_name,
        COALESCE(inv.inv_quantity_on_hand, 0) AS stock_level
    FROM 
        store s
    LEFT JOIN 
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
    LEFT JOIN 
        inventory inv ON s.s_store_sk = inv.inv_warehouse_sk
)
SELECT 
    s.s_store_name,
    si.total_profit AS store_profit,
    cs.total_web_profit AS customer_profit,
    CASE 
        WHEN cs.orders_count > 20 THEN 'High'
        WHEN cs.orders_count BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_order_level,
    CASE 
        WHEN stock_level = 0 THEN 'Out of Stock'
        ELSE CAST(stock_level AS STRING)
    END AS stock_status
FROM 
    sales_cte si
JOIN 
    store_info s ON si.ss_store_sk = s.s_store_sk
JOIN 
    customer_summary cs ON cs.c_customer_sk IN (
        SELECT DISTINCT ws_ship_customer_sk 
        FROM web_sales 
        WHERE ws_sold_date_sk = si.ss_sold_date_sk
    )
WHERE 
    si.profit_rank <= 5
ORDER BY 
    store_profit DESC, customer_profit DESC;
