
WITH  sales_per_date AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS date_rank
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
    HAVING 
        SUM(ws.ws_ext_sales_price) IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(s.ss_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        sales_per_date
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.total_purchases,
    ci.total_spent,
    CASE 
        WHEN ci.total_spent > avg_sales.avg_sales THEN 'Above Average'
        WHEN ci.total_spent < avg_sales.avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_spent DESC) AS gender_rank
FROM 
    customer_info ci
CROSS JOIN 
    average_sales avg_sales
WHERE 
    ci.total_purchases > 5
ORDER BY 
    ci.total_spent DESC;

