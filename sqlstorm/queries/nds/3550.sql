
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        i.i_item_desc,
        i.i_current_price
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
NullHandledReturns AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        sr_item_sk
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    NULLIF(ti.total_sales - nr.total_returns, 0) AS net_sales,
    CASE 
        WHEN NULLIF(ti.total_sales - nr.total_returns, 0) IS NOT NULL 
        THEN ROUND((ti.total_sales - nr.total_returns) / ti.total_sales * 100, 2)
        ELSE NULL
    END AS return_rate_percentage
FROM 
    TopItems ti
LEFT JOIN 
    NullHandledReturns nr ON ti.ws_item_sk = nr.sr_item_sk
ORDER BY 
    ti.total_sales DESC;
