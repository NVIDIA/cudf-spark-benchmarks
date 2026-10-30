
WITH  sales_summary AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY cs_item_sk, cs_order_number
),
customer_statistics AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_purchases,
        SUM(s.ss_net_paid) AS total_spent,
        COALESCE(MAX(s.ss_sales_price), 0) AS max_spent_in_single_purchase,
        COUNT(DISTINCT CASE WHEN s.ss_net_paid > 100 THEN s.ss_ticket_number END) AS high_value_purchases
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL
    GROUP BY c.c_customer_id, cd.cd_gender
)
SELECT 
    cs.cs_item_sk, 
    cs.total_quantity,
    cs.total_sales,
    ct.c_customer_id,
    ct.cd_gender,
    ct.total_store_purchases,
    ct.total_spent,
    ct.max_spent_in_single_purchase,
    ct.high_value_purchases,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = cs.cs_item_sk AND sr.sr_return_quantity > 0) AS total_returns,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_item_sk = cs.cs_item_sk) AS total_web_sales
FROM sales_summary cs
JOIN customer_statistics ct ON cs.cs_order_number = ct.total_store_purchases
WHERE cs.rank = 1 AND ct.total_store_purchases IS NOT NULL
ORDER BY cs.total_sales DESC, ct.total_store_purchases DESC;
