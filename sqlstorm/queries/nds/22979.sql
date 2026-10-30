
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price,
        AVG(ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 10000 AND 10010
    GROUP BY ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_sales,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_ranking AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.total_sales,
        sd.order_count,
        sd.max_sales_price,
        sd.min_sales_price,
        sd.avg_sales_price,
        sd.rank
    FROM customer_details cd
    LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cr.c_customer_sk,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    COALESCE(cr.total_sales, 0) AS total_sales,
    COALESCE(cr.order_count, 0) AS order_count,
    CASE 
        WHEN cr.rank IS NULL THEN 'Not Ranked'
        ELSE CONCAT('Rank ', cr.rank)
    END AS sales_rank,
    CASE 
        WHEN c.total_store_sales > c.total_web_sales THEN 'Higher Store Sales'
        WHEN c.total_store_sales < c.total_web_sales THEN 'Higher Web Sales'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM customer_ranking cr
FULL OUTER JOIN customer_details c ON cr.c_customer_sk = c.c_customer_sk
WHERE cr.total_sales IS NOT NULL OR c.c_customer_sk IS NULL
ORDER BY cr.total_sales DESC NULLS LAST;
