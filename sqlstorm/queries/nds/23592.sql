
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id
),
high_spenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    WHERE 
        cs.sales_rank <= 10
        AND cs.total_sales IS NOT NULL
),
promotional_sales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_paid) AS promo_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count,
        MAX(ws.ws_sales_price) AS highest_item_price
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
    GROUP BY 
        ws.ws_order_number
),
customer_promos AS (
    SELECT 
        hs.c_customer_id,
        ps.ws_order_number,
        ps.promo_sales,
        ps.item_count
    FROM 
        high_spenders hs
    JOIN 
        promotional_sales ps ON hs.order_count * 10 = ps.item_count
)
SELECT 
    cp.c_customer_id,
    COALESCE(cp.promo_sales, 0) AS total_promotional_sales,
    CASE 
        WHEN cp.item_count > 0 THEN 'YES'
        ELSE 'NO'
    END AS received_promotions,
    CASE 
        WHEN cp.promo_sales IS NULL THEN 'Did Not Spend'
        ELSE 'Spent' 
    END AS spending_status,
    CONCAT('Customer ', cp.c_customer_id, ' has ', COALESCE(cp.promo_sales, 0), ' in promotional sales.') AS summary_statement
FROM 
    customer_promos cp
FULL OUTER JOIN 
    high_spenders hs ON cp.c_customer_id = hs.c_customer_id
WHERE 
    cp.promo_sales IS NULL OR (hs.total_sales IS NOT NULL AND hs.total_sales > 1000)
ORDER BY 
    hs.total_sales DESC NULLS LAST;
