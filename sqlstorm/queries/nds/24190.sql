
WITH SeasonalSales AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') - 1)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01'))
    GROUP BY 
        ws_ship_date_sk
),
ReturnSales AS (
    SELECT 
        wr_returned_date_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_sales
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') - 1)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01'))
    GROUP BY 
        wr_returned_date_sk
)
SELECT 
    ds.d_date AS sales_date,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rs.total_returned_quantity, 0) AS total_quantity_returned,
    (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returned_sales, 0)) AS net_sales,
    (CASE 
        WHEN (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returned_sales, 0)) < 0 
        THEN NULL 
        ELSE ROUND(100.0 * COALESCE(rs.total_returned_sales, 0) / NULLIF(ss.total_sales, 0), 2) 
    END) AS return_percentage,
    DENSE_RANK() OVER (ORDER BY ds.d_date) AS date_rank
FROM 
    date_dim ds
LEFT JOIN 
    SeasonalSales ss ON ds.d_date_sk = ss.ws_ship_date_sk
LEFT JOIN 
    ReturnSales rs ON ds.d_date_sk = rs.wr_returned_date_sk
WHERE 
    ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-10-01'
ORDER BY 
    sales_date DESC
LIMIT 100 OFFSET 10;
