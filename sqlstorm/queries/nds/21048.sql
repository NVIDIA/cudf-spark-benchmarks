
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
LatestSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        MAX(ws_sold_date_sk) AS last_sold_date
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TotalReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    l.ws_item_sk,
    COALESCE(rp.price_rank, 0) AS price_rank,
    l.total_quantity,
    l.total_sales,
    COALESCE(tr.total_returns, 0) AS total_returns,
    CASE 
        WHEN l.total_sales = 0 THEN 'No Sales' 
        ELSE 'Sales Present' 
    END AS sales_status,
    CASE 
        WHEN COALESCE(tr.total_returns, 0) > l.total_quantity THEN 'High Return Rate' 
        ELSE 'Normal Return Rate' 
    END AS return_status,
    REPLACE(NULLIF(wp_url, ''), 'http://', '') AS clean_url
FROM 
    LatestSales l
LEFT JOIN 
    RankedSales rp ON l.ws_item_sk = rp.ws_item_sk AND rp.price_rank = 1
LEFT JOIN 
    TotalReturns tr ON l.ws_item_sk = tr.wr_item_sk
LEFT JOIN 
    web_page wp ON l.ws_item_sk = wp.wp_web_page_sk
WHERE 
    l.total_sales is not NULL
ORDER BY 
    l.total_sales DESC
LIMIT 100;
