
WITH RankedWebSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregateSales AS (
    SELECT 
        i.i_brand,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        RankedWebSales rws
    JOIN 
        item i ON rws.ws_item_sk = i.i_item_sk
    JOIN 
        web_sales ws ON rws.ws_order_number = ws.ws_order_number AND rws.ws_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_brand
),
StoreReturnsWithReasons AS (
    SELECT 
        sr.sr_return_quantity,
        sr.sr_net_loss,
        r.r_reason_desc
    FROM 
        store_returns sr
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        sr.sr_return_quantity > 0
)
SELECT 
    ag.i_brand,
    ag.total_quantity,
    ag.avg_net_profit,
    COALESCE(SUM(srr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(srr.sr_net_loss), 0) AS total_net_loss,
    AVG(NULLIF(srr.sr_net_loss, 0)) AS avg_net_loss
FROM 
    AggregateSales ag
LEFT JOIN 
    StoreReturnsWithReasons srr ON ag.i_brand = srr.r_reason_desc
GROUP BY 
    ag.i_brand,
    ag.total_quantity,
    ag.avg_net_profit
HAVING 
    AVG(COALESCE(srr.sr_net_loss, 0)) < 100 AND COUNT(srr.sr_return_quantity) > 5
ORDER BY 
    ag.total_quantity DESC
LIMIT 10;
