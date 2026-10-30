
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_demo AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        c.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_quantity,
        cs.total_catalog_quantity,
        cs.web_orders_count,
        cs.catalog_orders_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_sales cs
    JOIN customer_demo cd ON cs.c_customer_sk = cd.c_customer_sk
),
ranked_sales AS (
    SELECT 
        sa.*,
        RANK() OVER (PARTITION BY sa.cd_gender ORDER BY sa.total_web_quantity + sa.total_catalog_quantity DESC) as sales_rank
    FROM 
        sales_analysis sa
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.total_web_quantity,
    r.total_catalog_quantity,
    r.web_orders_count,
    r.catalog_orders_count,
    CASE 
        WHEN r.sales_rank <= 5 THEN 'Top Performer' 
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    ranked_sales r
WHERE 
    r.cd_marital_status = 'M'
    AND r.total_web_quantity > (SELECT AVG(total_web_quantity) FROM ranked_sales)
ORDER BY 
    r.total_web_quantity DESC
LIMIT 20;
