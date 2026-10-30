
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        cd.cd_gender,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender
),
top_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.d_year AS year,
        rc.cd_gender,
        rc.total_sales,
        rc.purchase_count
    FROM 
        ranked_customers rc
    JOIN 
        (SELECT DISTINCT d_year FROM date_dim ORDER BY d_year DESC LIMIT 5) AS last_five_years ON rc.d_year = last_five_years.d_year
    WHERE 
        rc.sales_rank <= 10
)
SELECT 
    tc.c_customer_id, 
    tc.year, 
    tc.cd_gender, 
    tc.total_sales, 
    tc.purchase_count,
    (SELECT COUNT(DISTINCT sr_item_sk) 
     FROM store_returns 
     WHERE sr_customer_sk = c.c_customer_sk) AS total_returns
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
ORDER BY 
    tc.total_sales DESC;
