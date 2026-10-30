
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
),
top_items AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        id.total_sales,
        RANK() OVER (ORDER BY id.total_sales DESC) AS item_rank
    FROM item_details id
    WHERE id.total_sales > 0
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    ti.i_item_desc,
    ti.i_current_price,
    ti.total_sales,
    ti.item_rank
FROM customer_summary cs
JOIN top_items ti ON cs.rank <= 5
LEFT JOIN web_site ws ON ws.web_site_sk = cs.c_customer_sk
WHERE 
    cs.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics) 
    AND ti.item_rank <= 10
ORDER BY cs.cd_gender, ti.total_sales DESC;
