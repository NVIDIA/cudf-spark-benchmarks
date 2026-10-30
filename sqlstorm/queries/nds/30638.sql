
WITH  sales_growth AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d_year) AS year_rank
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
previous_year_sales AS (
    SELECT 
        y1.d_year,
        y1.total_sales AS current_year_sales,
        COALESCE(y2.total_sales, 0) AS previous_year_sales,
        (y1.total_sales - COALESCE(y2.total_sales, 0)) / NULLIF(y2.total_sales, 0) AS growth_rate
    FROM 
        sales_growth y1 
    LEFT JOIN 
        sales_growth y2 ON y1.year_rank = y2.year_rank + 1
),
customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
top_categories AS (
    SELECT 
        i_category,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_category
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    g.d_year,
    g.total_sales,
    y.current_year_sales,
    y.previous_year_sales,
    y.growth_rate,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    tc.i_category,
    tc.total_sales AS category_sales
FROM 
    sales_growth g
JOIN 
    previous_year_sales y ON g.d_year = y.d_year
CROSS JOIN 
    customer_stats cs
CROSS JOIN 
    top_categories tc
WHERE 
    g.total_sales > 10000
    AND (cs.customer_count IS NOT NULL OR cs.avg_purchase_estimate IS NOT NULL)
ORDER BY 
    g.d_year, tc.total_sales DESC;
