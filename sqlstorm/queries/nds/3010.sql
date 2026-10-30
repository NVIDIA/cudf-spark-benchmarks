
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
TotalRefunds AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_refund
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.total_sales, 0) AS total_sales,
    COALESCE(TR.total_refund, 0) AS total_refund,
    (COALESCE(RS.total_sales, 0) - COALESCE(TR.total_refund, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(RS.total_sales, 0) = 0 THEN NULL 
        ELSE ROUND((COALESCE(RS.total_sales, 0) - COALESCE(TR.total_refund, 0)) / COALESCE(RS.total_sales, 1) * 100, 2)
    END AS refund_percentage
FROM 
    item i
LEFT JOIN (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
) AS RS ON i.i_item_sk = RS.ws_item_sk
LEFT JOIN TotalRefunds TR ON i.i_item_sk = TR.cr_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    net_sales DESC, 
    refund_percentage DESC
LIMIT 100;
