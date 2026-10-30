
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name || ' ' || cs.c_last_name AS customer_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        CASE 
            WHEN cs.total_sales > 1000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        COALESCE((SELECT COUNT(*)
                  FROM store_sales ss
                  WHERE ss.ss_customer_sk = cs.c_customer_sk
                  AND ss.ss_sold_date_sk >= (SELECT MIN(d.d_date_sk) 
                                               FROM date_dim d 
                                               WHERE d.d_year = 2022)), 0) AS store_sales_count
    FROM 
        customer_sales cs
    WHERE 
        cs.order_count > 0
),
customer_performance AS (
    SELECT 
        sa.*,
        ROW_NUMBER() OVER (PARTITION BY sa.customer_value ORDER BY sa.total_sales DESC) as rn
    FROM 
        sales_analysis sa
)
SELECT 
    cp.customer_name,
    cp.total_sales,
    cp.order_count,
    cp.customer_value,
    cp.store_sales_count
FROM 
    customer_performance cp
WHERE 
    cp.rn <= 5 
    AND (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL) > 0
ORDER BY 
    cp.total_sales DESC
LIMIT 5 OFFSET 10;

