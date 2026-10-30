
WITH normalized_cities AS (
    SELECT DISTINCT 
        UPPER(TRIM(ca_city)) AS city_name,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_city != ''
    GROUP BY UPPER(TRIM(ca_city))
),
customer_gender_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender
),
date_range AS (
    SELECT 
        d_date_sk,
        d_date,
        d_month_seq,
        d_year
    FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
sales_summary AS (
    SELECT 
        'web' AS sales_channel,
        ws_order_number AS order_number,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS total_items
    FROM web_sales
    GROUP BY ws_order_number
    UNION ALL
    SELECT 
        'catalog' AS sales_channel,
        cs_order_number AS order_number,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_item_sk) AS total_items
    FROM catalog_sales
    GROUP BY cs_order_number
    UNION ALL
    SELECT 
        'store' AS sales_channel,
        ss_ticket_number AS order_number,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_item_sk) AS total_items
    FROM store_sales
    GROUP BY ss_ticket_number
)
SELECT 
    nc.city_name,
    cs.customer_count,
    cs.average_purchase_estimate,
    SUM(ss.total_sales) AS total_sales,
    SUM(ss.total_items) AS total_items
FROM normalized_cities nc
LEFT JOIN customer_gender_stats cs ON cs.customer_count > 0
LEFT JOIN sales_summary ss ON ss.sales_channel = 'web'
    OR ss.sales_channel = 'catalog'
    OR ss.sales_channel = 'store'
GROUP BY nc.city_name, cs.customer_count, cs.average_purchase_estimate
ORDER BY total_sales DESC;
