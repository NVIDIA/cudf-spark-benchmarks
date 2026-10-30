
WITH  demographic_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM customer_demographics
    LEFT JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        MAX(ca_gmt_offset) AS max_gmt_offset
    FROM customer_address
    GROUP BY ca_state
),
shipping_details AS (
    SELECT 
        sm_ship_mode_id,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    JOIN ship_mode ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    GROUP BY sm_ship_mode_id
),
return_summary AS (
    SELECT 
        sr_reason_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_reason_sk
),
combined_summary AS (
    SELECT 
        ds.cd_demo_sk,
        ds.cd_gender,
        ds.cd_marital_status,
        ds.customer_count,
        ds.total_estimate,
        ds.highest_credit_rating,
        asu.unique_addresses,
        asu.max_gmt_offset,
        sd.sm_ship_mode_id,
        sd.total_net_profit,
        sd.avg_sales_price,
        rs.total_returns,
        rs.total_return_amount
    FROM demographic_summary ds
    JOIN address_summary asu ON asu.unique_addresses > 0
    JOIN shipping_details sd ON sd.total_orders > 0
    LEFT JOIN return_summary rs ON rs.total_returns > 0
)
SELECT 
    cb.cd_demo_sk,
    cb.cd_gender,
    CASE 
        WHEN cb.cd_marital_status IS NULL THEN 'Unknown'
        ELSE cb.cd_marital_status
    END AS marital_status,
    cb.customer_count,
    COALESCE(cb.total_estimate, 0) AS estimated_purchase,
    cb.max_gmt_offset,
    cb.sm_ship_mode_id,
    cb.total_net_profit,
    ROUND(cb.avg_sales_price, 2) AS rounded_avg_sales_price,
    COALESCE(cb.total_returns, 0) AS returns_count,
    COALESCE(cb.total_return_amount, 0) AS return_value
FROM combined_summary cb
WHERE (cb.total_net_profit IS NOT NULL OR cb.total_returns > 0)
AND cb.customer_count > (SELECT AVG(customer_count) FROM demographic_summary)
ORDER BY cb.total_net_profit DESC, cb.customer_count DESC
LIMIT 100;
