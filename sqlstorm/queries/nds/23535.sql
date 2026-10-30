
WITH  sales_trends AS (
    SELECT 
        d.d_date, 
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d.d_month_seq ORDER BY d.d_date DESC) AS month_rank
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
        AND d.d_month_seq IN (SELECT DISTINCT d_month_seq 
                               FROM date_dim 
                               WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
                               AND d_month_seq <= EXTRACT(MONTH FROM DATE '2002-10-01'))
    GROUP BY 
        d.d_date, d.d_month_seq
    UNION ALL
    SELECT 
        d.d_date, 
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d.d_month_seq ORDER BY d.d_date DESC) AS month_rank
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk 
    WHERE 
        d.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
        AND d.d_month_seq IN (SELECT DISTINCT d_month_seq 
                               FROM date_dim 
                               WHERE d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
                               AND d_month_seq <= EXTRACT(MONTH FROM DATE '2002-10-01'))
    GROUP BY 
        d.d_date, d.d_month_seq
),
latest_returns AS (
    SELECT 
        sr_returned_date_sk AS return_date_sk,
        SUM(sr_return_quantity) AS total_returns,
        sr_item_sk
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(sr_returned_date_sk) - 30 FROM store_returns)
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
final_report AS (
    SELECT 
        ts.total_sales, 
        ts.total_quantity, 
        lr.total_returns,
        COALESCE(ts.total_sales - lr.total_returns, 0) AS net_sales,
        RANK() OVER (ORDER BY COALESCE(ts.total_sales - lr.total_returns, 0) DESC) AS sales_rank
    FROM 
        sales_trends ts
    LEFT JOIN 
        latest_returns lr ON ts.month_rank = lr.return_date_sk
)
SELECT 
    f.total_sales, 
    f.total_quantity, 
    f.total_returns, 
    f.net_sales, 
    f.sales_rank
FROM 
    final_report f 
WHERE 
    f.net_sales IS NOT NULL
ORDER BY 
    f.sales_rank;
