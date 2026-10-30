WITH  sales_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
recent_purchases AS (
    SELECT 
        c.c_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_info AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        rp.last_purchase_date,
        DATE_PART('year', cast('2002-10-01' as date)) - DATE_PART('year', DATE '1970-01-01' + rp.last_purchase_date) AS years_since_last_purchase
    FROM 
        sales_data cs
    JOIN 
        recent_purchases rp ON cs.c_customer_sk = rp.c_customer_sk
    WHERE 
        cs.sales_rank <= 5
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(ci.total_sales, 0) AS total_sales,
    ci.order_count,
    ci.last_purchase_date,
    ci.years_since_last_purchase,
    CASE 
        WHEN ci.years_since_last_purchase < 1 THEN 'recent'
        WHEN ci.years_since_last_purchase BETWEEN 1 AND 3 THEN 'active'
        ELSE 'inactive'
    END AS customer_status
FROM 
    customer_info ci
ORDER BY 
    ci.total_sales DESC;