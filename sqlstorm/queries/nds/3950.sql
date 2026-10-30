
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(ir.sr_return_quantity), 0) AS total_returns,
        COALESCE(ROUND(AVG(CASE WHEN ir.sr_return_quantity > 0 THEN ir.sr_return_quantity END), 2), 0) AS avg_returned_quantity,
        id.total_sales,
        id.total_profit
    FROM 
        item i
    LEFT JOIN 
        RankedReturns ir ON i.i_item_sk = ir.sr_item_sk
    LEFT JOIN 
        ItemSales id ON i.i_item_sk = id.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, id.total_sales, id.total_profit
)
SELECT 
    it.i_item_sk,
    it.i_item_desc,
    it.total_returns,
    it.avg_returned_quantity,
    it.total_sales,
    it.total_profit,
    CASE 
        WHEN it.total_sales > 0 THEN ROUND((it.total_profit / it.total_sales) * 100, 2)
        ELSE 0 
    END AS profit_margin
FROM 
    ItemDetails it
WHERE 
    it.total_returns > 0 AND it.total_sales > 0
ORDER BY 
    profit_margin DESC
LIMIT 10;
