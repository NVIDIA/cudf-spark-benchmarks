
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ws.ws_net_profit IS NOT NULL
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_returning_customer_sk) AS return_count
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year BETWEEN 2021 AND 2023
        )
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.ws_sales_price,
    rs.ws_net_profit,
    COALESCE(fr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(fr.total_return_amount, 0) AS total_return_amount,
    (rs.ws_net_profit - COALESCE(fr.total_return_amount, 0)) AS net_profit_after_returns,
    (CASE 
        WHEN (COALESCE(fr.total_return_quantity, 0) > 0) 
            THEN 'Returns Found' 
        ELSE 'No Returns' 
        END) AS return_status
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    FilteredReturns fr ON i.i_item_sk = fr.cr_item_sk
WHERE 
    rs.rnk = 1
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
