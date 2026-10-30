WITH  sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN '2000-01-01' AND cast('2002-10-01' as date))
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.cd_purchase_estimate
    FROM customer_info ci
    WHERE 
        ci.cd_purchase_estimate IS NOT NULL AND 
        ci.cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate)
            FROM customer_demographics
        )
),
top_items AS (
    SELECT
        sd.ws_item_sk,
        CONCAT('Item_', sd.ws_item_sk) AS item_name,
        sd.total_quantity,
        sd.total_net_paid
    FROM sales_data sd
    WHERE sd.total_quantity > (
        SELECT AVG(total_quantity) FROM sales_data
    )
),
joined_data AS (
    SELECT
        hi.c_customer_sk,
        ti.item_name,
        ti.total_quantity,
        ti.total_net_paid,
        COALESCE(ca.ca_city, 'Unknown') AS city,
        (SELECT COUNT(*) FROM store s WHERE s.s_store_sk = hi.c_customer_sk % 10 + 1) AS store_count
    FROM high_value_customers hi
    LEFT JOIN top_items ti ON hi.c_customer_sk = ti.ws_item_sk
    LEFT JOIN customer_address ca ON hi.c_customer_sk = ca.ca_address_sk
)
SELECT 
    jd.c_customer_sk,
    jd.item_name,
    jd.total_quantity,
    jd.total_net_paid,
    jd.city,
    jd.store_count,
    CASE
        WHEN jd.total_net_paid IS NULL OR jd.total_quantity IS NULL THEN 'Insufficient Data'
        WHEN jd.total_net_paid > 1000 THEN 'High Value'
        ELSE 'Regular Customer'
    END AS customer_value
FROM joined_data jd
WHERE jd.store_count > 1 OR jd.city IS NOT NULL
ORDER BY jd.total_net_paid DESC, jd.store_count ASC, jd.item_name;