
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_ranks AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS warehouse_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_quantity,
    cs.total_profit,
    wr.total_orders,
    wr.warehouse_profit
FROM 
    customer_ranks c
LEFT JOIN 
    sales_summary cs ON c.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_item_sk IN (
            SELECT ws_item_sk 
            FROM sales_summary 
            WHERE rank <= 10
        )
    )
LEFT JOIN 
    warehouse_summary wr ON cs.ws_item_sk IN (
        SELECT DISTINCT cs_item_sk 
        FROM catalog_sales
        WHERE cs_order_number IN (
            SELECT DISTINCT ws.ws_order_number
            FROM web_sales ws
        )
    )
WHERE 
    c.purchase_rank <= 5
ORDER BY 
    c.c_last_name ASC, 
    c.c_first_name ASC;
