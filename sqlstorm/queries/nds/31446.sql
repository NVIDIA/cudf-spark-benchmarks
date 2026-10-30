WITH  MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price)
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year < (SELECT MAX(d2.d_year) FROM date_dim d2)
    GROUP BY 
        d.d_year
),
SalesComparisons AS (
    SELECT 
        m.d_year,
        m.total_sales AS current_year_sales,
        LAG(m.total_sales) OVER (ORDER BY m.d_year) AS previous_year_sales,
        (m.total_sales - LAG(m.total_sales) OVER (ORDER BY m.d_year)) / NULLIF(LAG(m.total_sales) OVER (ORDER BY m.d_year), 0) * 100 AS sales_growth_percentage
    FROM 
        MonthlySales m
)
SELECT 
    s.d_year,
    COALESCE(s.current_year_sales, 0) AS current_year_sales,
    COALESCE(s.previous_year_sales, 0) AS previous_year_sales,
    COALESCE(s.sales_growth_percentage, 0) AS sales_growth_percentage
FROM 
    SalesComparisons s
FULL OUTER JOIN 
    date_dim d ON s.d_year = d.d_year
WHERE 
    d.d_year IS NOT NULL 
ORDER BY 
    s.d_year DESC;