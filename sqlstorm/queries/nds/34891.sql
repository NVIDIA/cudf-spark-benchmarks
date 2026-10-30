
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
), 
InventoryCTE AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_net_profit) AS max_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), 
SalesComputation AS (
    SELECT
        si.ws_item_sk,
        COALESCE(ROW_NUMBER() OVER (PARTITION BY si.ws_item_sk ORDER BY si.ws_order_number DESC), 0) AS order_rank,
        inv.total_quantity_on_hand,
        si.ws_net_profit,
        ci.total_orders,
        ci.max_profit
    FROM 
        SalesCTE si
    LEFT JOIN 
        InventoryCTE inv ON si.ws_item_sk = inv.inv_item_sk
    INNER JOIN 
        CustomerInfo ci ON ci.total_orders > 5
) 
SELECT 
    sc.ws_item_sk,
    sc.total_quantity_on_hand,
    SUM(CASE WHEN sc.order_rank = 1 THEN sc.ws_net_profit ELSE 0 END) AS top_profit,
    AVG(sc.max_profit) AS avg_customer_profit,
    COUNT(CASE WHEN sc.total_orders > 10 THEN 1 END) AS high_order_customers
FROM 
    SalesComputation sc
GROUP BY 
    sc.ws_item_sk, sc.total_quantity_on_hand
HAVING 
    SUM(sc.ws_net_profit) > 1000 AND 
    AVG(sc.total_quantity_on_hand) IS NOT NULL
ORDER BY 
    top_profit DESC;
