
WITH  month_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
    UNION ALL
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
aggregated_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COALESCE(SUM(total_sales), 0) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        month_sales ms ON d.d_year = ms.d_year AND d.d_month_seq = ms.d_month_seq
    GROUP BY 
        d.d_year, d.d_month_seq
),
top_stores AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_name
    ORDER BY 
        store_sales DESC
    LIMIT 10
)
SELECT 
    ms.d_year,
    ms.d_month_seq,
    ms.total_sales,
    ts.s_store_name AS top_store,
    ts.store_sales AS top_store_sales
FROM 
    aggregated_sales ms
LEFT JOIN 
    top_stores ts ON 1=1
WHERE 
    ms.total_sales > (SELECT AVG(total_sales) FROM aggregated_sales) 
    OR ts.store_sales IS NULL
ORDER BY 
    ms.d_year, ms.d_month_seq DESC;
