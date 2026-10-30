
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc,
        COUNT(DISTINCT ws_order_number) AS total_sales_orders,
        SUM(ws_quantity) AS total_units_sold,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
HighVolumeItems AS (
    SELECT 
        item_stats.i_item_sk,
        item_stats.i_item_desc,
        item_stats.total_sales_orders,
        item_stats.total_units_sold,
        item_stats.avg_sales_price,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM 
        ItemStats item_stats
    LEFT JOIN 
        CustomerReturns cr ON item_stats.i_item_sk = cr.wr_returning_customer_sk
    WHERE 
        item_stats.total_units_sold > 100
)
SELECT 
    hvi.i_item_sk,
    hvi.i_item_desc,
    hvi.total_sales_orders,
    hvi.total_units_sold,
    hvi.avg_sales_price,
    hvi.total_return_amt,
    CASE 
        WHEN hvi.total_return_amt > (hvi.total_units_sold * hvi.avg_sales_price * 0.05) THEN 'High Returns'
        ELSE 'Normal Returns'
    END AS return_category
FROM 
    HighVolumeItems hvi
WHERE 
    hvi.total_sales_orders > 10
ORDER BY 
    hvi.total_units_sold DESC;

