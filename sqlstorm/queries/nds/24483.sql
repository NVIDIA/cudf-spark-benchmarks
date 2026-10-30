
WITH ranked_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL
        AND c.c_last_name IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        DENSE_RANK() OVER (ORDER BY r.total_sales DESC) AS value_rank
    FROM 
        ranked_sales r
    WHERE 
        r.total_sales > (SELECT AVG(total_sales) FROM ranked_sales)
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    COALESCE(hc.hd_income_band_sk, 0) AS income_band,
    CASE 
        WHEN h.total_sales > 1000 THEN 'High'
        WHEN h.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ARRAY_AGG(DISTINCT it.i_item_desc) AS purchased_items
FROM 
    high_value_customers h
LEFT JOIN 
    household_demographics hc ON h.c_customer_sk = hc.hd_demo_sk
LEFT JOIN 
    store_sales ss ON h.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    item it ON ss.ss_item_sk = it.i_item_sk
GROUP BY 
    h.c_first_name, h.c_last_name, h.total_sales, hc.hd_income_band_sk
HAVING 
    COUNT(DISTINCT it.i_item_sk) > 1 OR MAX(ss.ss_sales_price) IS NULL
ORDER BY 
    h.total_sales DESC, h.c_last_name;
