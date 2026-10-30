
WITH BaseSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
FilteredSales AS (
    SELECT 
        bs.ws_item_sk,
        bs.ws_sales_price,
        bs.ws_quantity,
        bs.ws_net_profit
    FROM 
        BaseSales bs
    WHERE 
        bs.rn = 1
        AND bs.ws_net_profit > 0
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
ItemReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.ws_sales_price,
    fs.ws_quantity,
    fs.ws_net_profit,
    COALESCE(ir.total_returns, 0) AS total_returns,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM 
    FilteredSales fs
LEFT JOIN 
    ItemReturns ir ON fs.ws_item_sk = ir.cr_item_sk
JOIN 
    CustomerStats cs ON cs.customer_count > 100
WHERE 
    fs.ws_sales_price > (SELECT AVG(ws.ws_sales_price) FROM web_sales ws)
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr 
        WHERE sr.sr_item_sk = fs.ws_item_sk AND sr.sr_return_quantity > 10
    )
ORDER BY 
    fs.ws_net_profit DESC
LIMIT 50;
