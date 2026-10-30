
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_net_profit,
        sd.total_orders
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    tsi.i_item_desc,
    tsi.total_quantity AS total_sales_quantity,
    tsi.total_net_profit,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN COALESCE(cr.total_returned_quantity, 0) = 0 THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status
FROM 
    TopSellingItems tsi
LEFT JOIN 
    CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
ORDER BY 
    tsi.total_net_profit DESC;
