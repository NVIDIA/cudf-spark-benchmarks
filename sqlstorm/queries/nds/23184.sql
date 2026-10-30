
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_preferred_cust_flag, cd.cd_gender
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
item_analysis AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count,
        SUM(ws.ws_net_profit) AS total_profit_item,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price,
        CASE 
            WHEN SUM(ws.ws_quantity) > 100 THEN 'High Seller'
            WHEN SUM(ws.ws_quantity) BETWEEN 50 AND 100 THEN 'Medium Seller'
            WHEN SUM(ws.ws_quantity) < 50 THEN 'Low Seller'
        END AS sales_category
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_preferred_cust_flag,
        ws.total_orders,
        ia.sales_count,
        ia.total_profit_item,
        ia.sales_category
    FROM 
        customer_summary cs
    LEFT JOIN 
        warehouse_summary ws ON cs.c_customer_sk = ws.total_orders
    LEFT JOIN 
        item_analysis ia ON cs.total_quantity = ia.sales_count
    WHERE
        cs.rn = 1
        AND (ia.total_profit_item IS NOT NULL OR ws.total_orders > 10)
)
SELECT 
    f.c_customer_sk,
    f.c_preferred_cust_flag,
    COALESCE(f.total_orders, 0) AS total_orders,
    COALESCE(f.sales_count, 0) AS sales_count,
    COALESCE(f.total_profit_item, 0.00) AS total_profit_item,
    f.sales_category
FROM 
    final_summary f
WHERE 
    (f.total_profit_item > 1000 OR f.sales_count > 50)
ORDER BY 
    f.total_profit_item DESC, f.sales_count ASC
LIMIT 100;
