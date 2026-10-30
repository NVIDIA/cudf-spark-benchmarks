
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_net_loss,
        sr_store_sk,
        sr_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
WebSalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        MIN(ws_sold_date_sk) AS first_sold_date,
        MAX(ws_sold_date_sk) AS last_sold_date
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
PopularItems AS (
    SELECT 
        cu.c_customer_id,
        ci.i_item_id,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned,
        ws.total_quantity,
        ws.total_profit
    FROM 
        customer cu
    JOIN 
        CustomerReturns sr ON cu.c_customer_sk = sr.sr_customer_sk
    JOIN 
        WebSalesData ws ON sr.sr_item_sk = ws.ws_item_sk
    JOIN 
        item ci ON sr.sr_item_sk = ci.i_item_sk
    WHERE 
        sr.rn = 1
    GROUP BY 
        cu.c_customer_id, ci.i_item_id, ws.total_quantity, ws.total_profit
)
SELECT 
    pi.c_customer_id,
    pi.i_item_id,
    pi.total_returned,
    pi.total_quantity,
    pi.total_profit,
    CASE 
        WHEN pi.total_quantity > 1000 THEN 'High'
        WHEN pi.total_quantity > 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume,
    COALESCE(ROUND((pi.total_profit / NULLIF(pi.total_quantity, 0)), 2), 0) AS avg_profit_per_item
FROM 
    PopularItems pi
WHERE 
    pi.total_returned > 0
ORDER BY 
    pi.total_profit DESC
LIMIT 10;
