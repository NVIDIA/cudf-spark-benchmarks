
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),
HighValueItems AS (
    SELECT 
        ir.i_item_sk,
        ir.i_product_name,
        SUM(COALESCE(rs.ws_net_profit, 0)) AS total_profit
    FROM 
        item ir
    LEFT JOIN 
        RankedSales rs ON ir.i_item_sk = rs.ws_item_sk
    GROUP BY 
        ir.i_item_sk, ir.i_product_name
    HAVING 
        SUM(COALESCE(rs.ws_net_profit, 0)) > 10000
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    hvi.i_product_name,
    hvi.total_profit
FROM 
    warehouse w 
JOIN 
    inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
JOIN 
    HighValueItems hvi ON i.inv_item_sk = hvi.i_item_sk
WHERE 
    w.w_state = 'NY'
ORDER BY 
    hvi.total_profit DESC;
