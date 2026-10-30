
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
sales_ranked AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales IS NOT NULL
),
final_result AS (
    SELECT 
        sr.c_customer_id,
        sr.total_sales,
        d.customer_count,
        d.max_purchase_estimate,
        CASE 
            WHEN sr.sales_rank <= 10 THEN 'Top Customer'
            WHEN sr.sales_rank <= 50 THEN 'Mid Customer'
            ELSE 'Low Customer'
        END AS customer_category
    FROM 
        sales_ranked sr
    LEFT JOIN 
        demographics d ON d.customer_count > 5 AND d.max_purchase_estimate IS NOT NULL
)
SELECT 
    fr.c_customer_id,
    fr.total_sales,
    fr.customer_category,
    COALESCE(fr.customer_count, 0) AS customer_count
FROM 
    final_result fr
WHERE 
    fr.total_sales > 1000 
    OR fr.customer_category = 'Top Customer'
ORDER BY 
    fr.total_sales DESC
LIMIT 1000;
