
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) as profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451600
    GROUP BY 
        ws.ws_item_sk
),
recent_returns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
high_performers AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(rr.total_returned, 0) AS total_returned,
        (sd.total_profit - COALESCE(rr.total_returned * i.i_current_price, 0)) AS net_profit_after_returns
    FROM 
        item i
    JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        recent_returns rr ON i.i_item_sk = rr.sr_item_sk
    WHERE 
        sd.profit_rank <= 10
)
SELECT 
    hp.i_item_id,
    hp.i_item_desc,
    hp.total_quantity,
    hp.total_profit,
    hp.total_returned,
    hp.net_profit_after_returns,
    ROUND(hp.net_profit_after_returns / NULLIF(hp.total_quantity, 0), 2) AS avg_profit_per_item
FROM 
    high_performers hp
ORDER BY 
    hp.net_profit_after_returns DESC;
