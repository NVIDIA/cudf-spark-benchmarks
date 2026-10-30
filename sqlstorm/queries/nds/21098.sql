WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND dd.d_dow IN (1, 2, 3) 
    GROUP BY 
        ws.ws_item_sk
),

ReturnsInfo AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),

FinalReport AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(ri.total_returns, 0) > 0 THEN 
                (rs.total_sales - ri.total_return_amt) / NULLIF(rs.total_sales, 0)
            ELSE 
                NULL
        END AS net_sales_percentage
    FROM 
        RankedSales rs
    LEFT JOIN 
        ReturnsInfo ri ON rs.ws_item_sk = ri.wr_item_sk
    WHERE 
        rs.rank = 1
)

SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.total_return_amt,
    f.net_sales_percentage,
    CASE 
        WHEN f.net_sales_percentage IS NULL THEN 'No Sales'
        WHEN f.net_sales_percentage < 0.5 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC
LIMIT 100
OFFSET 0;