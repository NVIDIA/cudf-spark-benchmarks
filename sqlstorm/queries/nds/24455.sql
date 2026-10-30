
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE wp.wp_creation_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        NULLIF(AVG(cd.cd_purchase_estimate), 0) AS average_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
sales_exceptions AS (
    SELECT 
        ss.ss_item_sk,
        COUNT(ss.ss_ticket_number) AS return_count
    FROM store_sales ss
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    GROUP BY ss.ss_item_sk
    HAVING COUNT(sr.sr_returned_date_sk) > 0
),
final_output AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        ci.demographic_count,
        ci.male_count,
        COALESCE(se.return_count, 0) AS return_count
    FROM ranked_sales r
    JOIN customer_info ci ON ci.c_customer_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_first_name LIKE '%John%' LIMIT 1)
    LEFT JOIN sales_exceptions se ON se.ss_item_sk = r.ws_item_sk
    WHERE r.rank = 1
)
SELECT 
    fo.ws_item_sk,
    fo.total_quantity,
    fo.total_sales,
    fo.demographic_count,
    fo.male_count,
    CASE 
        WHEN fo.return_count > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_returns
FROM final_output fo
WHERE fo.total_sales IS NOT NULL
ORDER BY fo.total_sales DESC;
