
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458596 AND 2458599  
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        w.w_city,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_city
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discounts
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458596 AND 2458599  
    GROUP BY w.w_warehouse_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    cs.order_count,
    ws.total_sales,
    ws.total_discounts,
    wh.total_inventory
FROM customer_summary cs
JOIN sales_summary ws ON cs.c_customer_sk = (
    SELECT DISTINCT ws_ship_customer_sk
    FROM web_sales
    WHERE ws_web_page_sk IN (
        SELECT wp_web_page_sk
        FROM web_page
        WHERE wp_access_date_sk BETWEEN 2458596 AND 2458599  
    )
)
JOIN warehouse_summary wh ON ws.w_warehouse_id = wh.w_warehouse_id
WHERE cs.total_profit > 1000
ORDER BY cs.total_profit DESC
LIMIT 100;
