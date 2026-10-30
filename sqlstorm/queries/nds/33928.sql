
WITH  SalesGrowth AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023 
    GROUP BY 
        d.d_year
),
TotalSales AS (
    SELECT 
        d.d_year,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS store_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS catalog_sales
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023 
    GROUP BY 
        d.d_year
),
CombinedSales AS (
    SELECT 
        sg.d_year,
        sg.total_sales * 1.0 AS web_sales, 
        ts.store_sales, 
        ts.catalog_sales,
        (sg.total_sales + COALESCE(ts.store_sales, 0) + COALESCE(ts.catalog_sales, 0)) AS total_all_sales 
    FROM 
        SalesGrowth sg 
    LEFT JOIN 
        TotalSales ts ON sg.d_year = ts.d_year
),
SalesAnalysis AS (
    SELECT 
        d.d_year,
        web_sales,
        store_sales,
        catalog_sales,
        total_all_sales,
        (web_sales - LAG(web_sales) OVER (ORDER BY d_year)) / NULLIF(LAG(web_sales) OVER (ORDER BY d_year), 0) * 100 AS sales_growth_percentage
    FROM 
        CombinedSales d
)
SELECT 
    d.d_year,
    d.web_sales,
    d.store_sales,
    d.catalog_sales,
    d.total_all_sales,
    COALESCE(d.sales_growth_percentage, 0) AS sales_growth_percentage
FROM 
    SalesAnalysis d
WHERE 
    d.web_sales > 100000 AND d.store_sales IS NOT NULL
ORDER BY 
    d.d_year;
