
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
store_summary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
profit_summary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    cs.c_first_name, 
    cs.c_last_name,
    cs.total_quantity AS customer_total_quantity,
    cs.total_sales AS customer_total_sales,
    ss.s_store_name,
    ss.total_quantity AS store_total_quantity,
    ss.total_sales AS store_total_sales,
    ps.total_profit AS warehouse_total_profit
FROM 
    customer_summary cs
JOIN 
    store_summary ss ON cs.total_sales > 1000
JOIN 
    profit_summary ps ON ps.total_profit > 0
ORDER BY 
    cs.total_sales DESC, 
    ss.total_sales DESC
LIMIT 50;
