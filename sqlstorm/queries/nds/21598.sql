
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_date = DATE '2002-10-01'
        )
    GROUP BY 
        ws_item_sk
),
low_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_catalog_quantity,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_week_seq = (
                    SELECT 
                        d_week_seq 
                    FROM 
                        date_dim 
                    WHERE 
                        d_date = DATE '2002-10-01'
                )
        )
    GROUP BY 
        cs_item_sk
),
combined_sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        l.total_catalog_quantity,
        l.order_count,
        r.sales_rank
    FROM 
        ranked_sales r
    LEFT JOIN 
        low_sales l ON r.ws_item_sk = l.cs_item_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(c.c_first_name, 'Unknown') AS first_name,
    COALESCE(c.c_last_name, 'Unknown') AS last_name,
    cs.total_quantity,
    cs.total_sales,
    cs.total_catalog_quantity,
    CASE 
        WHEN cs.sales_rank IS NULL THEN 'No Web Sales'
        WHEN cs.total_quantity > 100 THEN 'Large Sales'
        ELSE 'Small Sales'
    END AS sales_type
FROM 
    customer c 
LEFT JOIN 
    combined_sales cs ON cs.ws_item_sk = c.c_customer_sk
WHERE 
    c.c_birth_year < EXTRACT(YEAR FROM DATE '2002-10-01') - 21
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NOT NULL)
ORDER BY 
    cs.total_sales DESC,
    first_name ASC NULLS LAST
LIMIT 50;
