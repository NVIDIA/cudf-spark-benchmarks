
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM 
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND d.d_date_sk = ws.ws_sold_date_sk
        LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
),
PerformanceMetrics AS (
    SELECT 
        d_year,
        total_store_sales,
        total_web_sales,
        total_catalog_sales,
        total_store_profit,
        total_web_profit,
        total_catalog_profit,
        (total_store_sales + total_web_sales + total_catalog_sales) AS total_sales,
        (total_store_profit + total_web_profit + total_catalog_profit) AS total_profit
    FROM 
        SalesSummary
)
SELECT 
    p.d_year,
    p.total_sales,
    p.total_profit,
    (p.total_profit / p.total_sales) * 100 AS profit_margin,
    ROW_NUMBER() OVER (ORDER BY p.total_sales DESC) AS sales_rank
FROM 
    PerformanceMetrics p
ORDER BY 
    p.total_sales DESC;
