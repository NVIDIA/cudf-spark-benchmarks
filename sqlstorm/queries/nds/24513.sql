
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_item_sk = ws.ws_item_sk)
), 
high_return_items AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr 
    WHERE 
        cr.cr_return_quantity IS NOT NULL 
    GROUP BY 
        cr.cr_item_sk
), 
sales_summary AS (
    SELECT 
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(CASE 
                WHEN cs.cs_ext_discount_amt > 0 THEN 1 
                ELSE 0 
            END) AS discount_count,
        AVG(CASE 
                WHEN cs.cs_ext_tax IS NOT NULL THEN cs.cs_ext_tax 
                ELSE 0 
            END) AS average_tax,
        SUM(cs.cs_net_profit) AS net_profit
    FROM 
        catalog_sales cs 
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    i.i_item_desc,
    rsi.total_sales,
    rsi.discount_count,
    rsi.average_tax,
    hri.total_returns,
    COALESCE(rsi.total_sales, 0) - COALESCE(hri.total_returns, 0) AS net_sales_after_returns,
    CASE 
        WHEN COALESCE(hri.total_returns, 0) > 10 THEN 'High Return'
        WHEN COALESCE(hri.total_returns, 0) BETWEEN 1 AND 10 THEN 'Moderate Return'
        ELSE 'Low Return' 
    END AS return_category
FROM 
    sales_summary rsi
FULL OUTER JOIN 
    high_return_items hri ON rsi.item_sk = hri.cr_item_sk
JOIN 
    item i ON rsi.item_sk = i.i_item_sk
WHERE 
    rsi.total_sales IS NOT NULL OR hri.total_returns IS NOT NULL
ORDER BY 
    net_sales_after_returns DESC, 
    i.i_item_desc ASC
LIMIT 50;

