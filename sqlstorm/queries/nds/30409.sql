
WITH  sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IS NOT NULL
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM 
        customer AS c
    JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cs.cs_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.total_sales, 0) AS total_sales
    FROM 
        customer AS c
    LEFT JOIN (
        SELECT 
            c_customer_sk, 
            SUM(total_sales) AS total_sales
        FROM 
            sales_hierarchy
        GROUP BY 
            c_customer_sk
    ) AS s ON c.c_customer_sk = s.c_customer_sk
),
max_sales AS (
    SELECT 
        MAX(total_sales) AS max_total_sales 
    FROM 
        sales_summary
),
ranked_sales AS (
    SELECT
        ss.*,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary AS ss
    WHERE 
        total_sales > (SELECT max_total_sales FROM max_sales) * 0.1
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10%'
        WHEN r.sales_rank <= 20 THEN 'Top 20%'
        ELSE 'Others'
    END AS sales_category
FROM 
    ranked_sales AS r
ORDER BY 
    r.sales_rank;
