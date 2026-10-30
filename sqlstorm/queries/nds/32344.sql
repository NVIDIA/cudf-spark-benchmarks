
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
        c.c_birth_day, c.c_birth_month, c.c_birth_year

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ws.ws_ext_sales_price) * 1.1 AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name,
        c.c_birth_day, c.c_birth_month, c.c_birth_year
),
ranked_sales AS (
    SELECT 
        customer_name,
        SUM(total_sales) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(total_sales) DESC) AS sales_rank
    FROM 
        sales_hierarchy
    GROUP BY 
        customer_name
)
SELECT 
    rs.customer_name,
    rs.total_sales,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales Data'
        WHEN rs.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_category
FROM 
    ranked_sales rs
LEFT JOIN 
    customer_demographics cd ON rs.customer_name LIKE '%' || cd.cd_demo_sk || '%'
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND cd.cd_credit_rating <> 'Poor'
    AND rs.total_sales > 10000
ORDER BY 
    rs.sales_rank;
