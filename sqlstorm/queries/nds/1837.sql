
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
),
StoreSales AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ss_item_sk
),
Returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_holiday = 'Y'
        )
    GROUP BY 
        sr_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(rs.total_quantity, 0) AS total_web_sales,
    COALESCE(ss.total_sales, 0) AS total_store_sales,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    (COALESCE(rs.total_quantity, 0) - COALESCE(ss.total_sales, 0) + COALESCE(r.total_return_amt, 0)) AS net_sales,
    rs.ws_item_sk
FROM 
    item i
LEFT JOIN 
    (SELECT * FROM RankedSales WHERE price_rank = 1) rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    StoreSales ss ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    Returns r ON i.i_item_sk = r.sr_item_sk
WHERE 
    (COALESCE(ss.total_sales, 0) > 5000 OR COALESCE(rs.total_quantity, 0) > 5000) 
    AND i.i_current_price IS NOT NULL
ORDER BY 
    net_sales DESC
LIMIT 100;
