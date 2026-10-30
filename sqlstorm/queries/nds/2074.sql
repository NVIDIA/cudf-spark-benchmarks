
WITH SaleData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (
            SELECT 
                MAX(d_date_sk) - 30 
            FROM 
                date_dim
            WHERE 
                d_current_month = 'Y'
        )
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SaleData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rank <= 10
)
SELECT 
    ts.ws_item_sk,
    ts.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    AVG(ws.ws_ext_sales_price) AS avg_sales_price
FROM 
    TopSales ts
LEFT JOIN 
    web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
GROUP BY 
    ts.ws_item_sk, ts.i_item_desc, ts.total_quantity, ts.total_net_profit
ORDER BY 
    total_net_profit DESC
LIMIT 10;
