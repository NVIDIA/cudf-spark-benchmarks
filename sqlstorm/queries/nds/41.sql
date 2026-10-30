
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_net_profit
    FROM 
        SalesSummary ss
    WHERE 
        ss.item_rank <= 10
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
CombinedResults AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity_sold,
        ti.total_net_profit,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_product_name,
    cr.total_quantity_sold,
    cr.total_net_profit,
    cr.total_returned_quantity,
    (CR.total_net_profit / NULLIF(cr.total_quantity_sold, 0)) AS net_profit_per_item,
    CASE 
        WHEN cr.total_returned_quantity > (0.2 * cr.total_quantity_sold) THEN 'High Return'
        WHEN cr.total_returned_quantity BETWEEN (0.1 * cr.total_quantity_sold) AND (0.2 * cr.total_quantity_sold) THEN 'Medium Return'
        ELSE 'Low Return' 
    END AS return_rate_category
FROM 
    item
JOIN 
    CombinedResults cr ON item.i_item_sk = cr.ws_item_sk
ORDER BY 
    cr.total_net_profit DESC, 
    cr.total_returned_quantity ASC;
