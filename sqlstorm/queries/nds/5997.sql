
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ra.ws_item_sk,
        ra.total_quantity,
        ra.total_net_profit,
        i.i_product_name,
        i.i_item_desc,
        sm.sm_carrier
    FROM 
        RankedSales ra
    JOIN 
        item i ON ra.ws_item_sk = i.i_item_sk
    JOIN 
        ship_mode sm ON ra.ws_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
    WHERE 
        ra.profit_rank <= 10
)
SELECT 
    ti.i_product_name,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    COUNT(DISTINCT sr.sr_item_sk) AS num_returns
FROM 
    TopItems ti
LEFT JOIN 
    store_returns sr ON ti.ws_item_sk = sr.sr_item_sk
GROUP BY 
    ti.i_product_name, ti.i_item_desc, ti.total_quantity, ti.total_net_profit
ORDER BY 
    ti.total_net_profit DESC;
