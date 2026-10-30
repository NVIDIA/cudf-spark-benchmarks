
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country = 'USA'
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
), 
HighProfitItems AS (
    SELECT 
        ir.i_item_id, 
        rs.total_quantity, 
        rs.total_profit,
        rs.ws_item_sk
    FROM 
        RankedSales rs
    JOIN 
        item ir ON rs.ws_item_sk = ir.i_item_sk
    WHERE 
        rs.profit_rank = 1
)
SELECT 
    hpi.i_item_id, 
    hpi.total_quantity, 
    hpi.total_profit, 
    COALESCE(sm.sm_type, 'Unknown') AS shipping_mode, 
    COUNT(DISTINCT wh.w_warehouse_sk) AS number_of_warehouses 
FROM 
    HighProfitItems hpi
LEFT JOIN 
    web_sales ws ON hpi.ws_item_sk = ws.ws_item_sk 
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN 
    inventory inv ON hpi.ws_item_sk = inv.inv_item_sk 
JOIN 
    warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
GROUP BY 
    hpi.i_item_id, hpi.total_quantity, hpi.total_profit, sm.sm_type
HAVING 
    hpi.total_profit > (SELECT AVG(total_profit) FROM HighProfitItems)
ORDER BY 
    hpi.total_profit DESC;
