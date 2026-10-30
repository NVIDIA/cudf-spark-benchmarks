
WITH  sales_growth AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    HAVING 
        d.d_year >= 2020
), ranked_growth AS (
    SELECT 
        d.d_year,
        sg.total_sales,
        LAG(sg.total_sales) OVER (ORDER BY d.d_year) AS previous_year_sales,
        (sg.total_sales - COALESCE(LAG(sg.total_sales) OVER (ORDER BY d.d_year), 0)) / NULLIF(LAG(sg.total_sales) OVER (ORDER BY d.d_year), 0) * 100 AS growth_percentage
    FROM 
        sales_growth sg
    JOIN 
        date_dim d ON sg.d_year = d.d_year
), customer_stats AS (
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer cu
    LEFT JOIN 
        web_sales ws ON cu.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        cu.c_customer_sk, cu.c_first_name, cu.c_last_name
), top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.order_count,
        c.total_spent,
        DENSE_RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        customer_stats c
    WHERE 
        c.total_spent > 1000
)
SELECT 
    rg.d_year,
    COUNT(DISTINCT tc.c_customer_sk) AS unique_top_customers,
    AVG(tc.total_spent) AS avg_spent_by_top_customers,
    SUM(rg.growth_percentage) AS total_growth_percentage
FROM 
    ranked_growth rg
JOIN 
    top_customers tc ON rg.d_year = tc.c_customer_sk
GROUP BY 
    rg.d_year
ORDER BY 
    rg.d_year ASC;
