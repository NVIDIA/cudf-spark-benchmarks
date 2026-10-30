
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
HighPerformanceStores AS (
    SELECT 
        r.ss_store_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN CONCAT('Mr. ', c.c_first_name)
            WHEN cd_gender = 'F' THEN CONCAT('Ms. ', c.c_first_name)
            ELSE c.c_first_name
        END AS salutation,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ss_store_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        r.rank = 1 AND r.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
),
SalesTrend AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS yearly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
SalesWithGrowth AS (
    SELECT 
        s1.d_year,
        s1.yearly_sales,
        LAG(s1.yearly_sales) OVER (ORDER BY s1.d_year) AS previous_year_sales,
        CASE 
            WHEN LAG(s1.yearly_sales) OVER (ORDER BY s1.d_year) IS NULL THEN NULL
            ELSE (s1.yearly_sales - LAG(s1.yearly_sales) OVER (ORDER BY s1.d_year)) / NULLIF(LAG(s1.yearly_sales) OVER (ORDER BY s1.d_year), 0)
        END AS growth_rate
    FROM 
        SalesTrend s1
)
SELECT 
    hps.salutation,
    hps.c_customer_id,
    hps.total_sales,
    swg.d_year,
    swg.yearly_sales,
    swg.growth_rate
FROM 
    HighPerformanceStores hps
LEFT JOIN 
    SalesWithGrowth swg ON hps.total_sales = (SELECT MAX(total_sales) FROM HighPerformanceStores)
WHERE 
    hps.total_sales IS NOT NULL
ORDER BY
    swg.d_year DESC, 
    hps.total_sales DESC;
