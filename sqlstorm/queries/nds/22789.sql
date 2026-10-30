WITH ranked_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS item_rank,
        COALESCE(NULLIF(SUBSTRING(i.i_item_desc FROM 1 FOR 10), ''), 'Unknown') AS short_desc
    FROM item i
    WHERE i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_price
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
address_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_zip DESC) AS city_rank
    FROM customer_address ca
    WHERE ca.ca_state IS NOT NULL
)
SELECT 
    r.item_rank,
    r.i_item_id,
    r.short_desc,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_revenue, 0) AS total_revenue,
    ad.ca_city,
    ad.ca_state,
    CASE 
        WHEN ad.city_rank IS NULL THEN 'Not Ranked'
        ELSE 'Ranked'
    END AS city_rank_status
FROM ranked_items r
LEFT JOIN sales_data sd ON r.i_item_sk = sd.ws_item_sk
FULL OUTER JOIN address_data ad ON ad.ca_address_sk = r.i_item_sk
WHERE 
    (sd.total_sales > 100 OR ad.ca_state IS NULL)
    AND (r.item_rank <= 5 OR r.short_desc LIKE '%special%')
ORDER BY 
    r.i_item_id DESC, 
    total_revenue DESC NULLS LAST
LIMIT 100;