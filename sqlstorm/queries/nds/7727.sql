
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN total_web_sales > total_store_sales THEN 'Web'
            WHEN total_store_sales > total_web_sales THEN 'Store'
            ELSE 'Equal'
        END AS preferred_sales_channel,
        COUNT(*) AS customer_count
    FROM 
        customer_sales
    GROUP BY 
        CASE 
            WHEN total_web_sales > total_store_sales THEN 'Web'
            WHEN total_store_sales > total_web_sales THEN 'Store'
            ELSE 'Equal'
        END
),
sales_distribution AS (
    SELECT 
        preferred_sales_channel,
        customer_count,
        (customer_count * 100.0 / SUM(customer_count) OVER ()) AS percentage
    FROM 
        sales_summary
)
SELECT 
    preferred_sales_channel,
    customer_count,
    ROUND(percentage, 2) AS percentage
FROM 
    sales_distribution
ORDER BY 
    customer_count DESC;
