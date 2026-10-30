
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_net_profit,
        MAX(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS max_sales_price,
        MIN(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS min_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(cd.cd_gender, 'U') AS gender
    FROM 
        item i
    LEFT JOIN customer_demographics cd ON i.i_item_sk = cd.cd_demo_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    SUM(rp.total_net_profit) AS total_net_profit,
    AVG(rp.total_net_profit) AS avg_net_profit,
    SUM(COALESCE(cr.return_count, 0)) AS total_returns,
    COALESCE(MAX(rp.max_sales_price), 0) AS highest_sale_price,
    COALESCE(MIN(rp.min_sales_price), 0) AS lowest_sale_price,
    COUNT(DISTINCT id.gender) AS gender_variance
FROM 
    ItemDetails id
LEFT JOIN RankedSales rp ON id.i_item_sk = rp.ws_item_sk AND rp.rn = 1
LEFT JOIN CustomerReturns cr ON id.i_item_sk = cr.wr_item_sk
WHERE 
    (rp.ws_net_profit > 100 OR cr.total_return_amount IS NOT NULL)
    AND (id.gender IS NULL OR id.gender != 'F' OR id.gender != 'M')
GROUP BY 
    id.i_item_id, id.i_product_name
HAVING 
    SUM(rp.total_net_profit) > 5000
ORDER BY 
    total_net_profit DESC, id.i_product_name ASC
LIMIT 100;
