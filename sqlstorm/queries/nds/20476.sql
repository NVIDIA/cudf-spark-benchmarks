
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < 500 THEN 'Low Sales'
            WHEN cs.total_sales BETWEEN 500 AND 1500 THEN 'Medium Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        customer_sales cs
),
promotional_items AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.sales_category,
    COALESCE(pi.promo_sales, 0) AS promotional_sales,
    (s.total_sales - COALESCE(pi.promo_sales, 0)) AS net_sales,
    CASE 
        WHEN (s.total_sales IS NOT NULL AND pi.promo_sales IS NOT NULL) THEN 
            ROUND(((s.total_sales - COALESCE(pi.promo_sales, 0)) / s.total_sales) * 100, 2)
        ELSE 
            NULL 
    END AS sales_percentage_of_promo
FROM 
    sales_summary s
LEFT JOIN 
    promotional_items pi ON pi.item_count > 0
WHERE 
    s.sales_category IN ('Medium Sales', 'High Sales') 
    AND s.total_sales > (SELECT AVG(total_sales) FROM sales_summary WHERE sales_category = 'High Sales') 
ORDER BY 
    s.total_sales DESC
LIMIT 10;
