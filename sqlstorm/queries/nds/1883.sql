
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        i.i_item_desc,
        i.i_current_price
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_profit,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    (ti.total_net_profit - COALESCE(cr.total_returned_quantity, 0) * ti.i_current_price) AS adjusted_net_profit
FROM 
    TopItems ti
LEFT JOIN 
    CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
ORDER BY 
    adjusted_net_profit DESC;
