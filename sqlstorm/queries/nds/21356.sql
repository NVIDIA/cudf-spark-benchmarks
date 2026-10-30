
WITH  demo_income AS (
    SELECT hd_demo_sk, ib_lower_bound, ib_upper_bound
    FROM household_demographics h
    JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
),
item_info AS (
    SELECT i.i_item_sk, i.i_product_name, i.i_current_price, i.i_brand
    FROM item i
    WHERE i_rec_start_date <= DATE '2002-10-01' AND (i_rec_end_date IS NULL OR i_rec_end_date >= DATE '2002-10-01')
),
date_filtered AS (
    SELECT d.d_date_sk, d.d_date, d.d_week_seq
    FROM date_dim d
    WHERE d.d_current_year = '1' AND (d.d_holiday IS NULL OR d.d_holiday = 'N')
),
sales_summary AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ws_item_sk
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_filtered)
    GROUP BY ws_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.ib_lower_bound,
        d.ib_upper_bound
    FROM customer c
    LEFT JOIN demo_income d ON c.c_current_cdemo_sk = d.hd_demo_sk
),
return_stats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
final_summary AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        CASE 
            WHEN ss.total_sales > 0 THEN (rs.total_returns::numeric / ss.total_sales) * 100
            ELSE NULL 
        END AS return_rate
    FROM customer_details ci
    LEFT JOIN sales_summary ss ON ss.ws_item_sk = (
        SELECT i_item_sk
        FROM item_info
        WHERE i_brand = 'BrandX' 
        ORDER BY i_current_price DESC 
        LIMIT 1
    )
    LEFT JOIN return_stats rs ON rs.sr_item_sk = (
        SELECT i_item_sk
        FROM item_info
        WHERE i_brand = 'BrandX' 
        ORDER BY i_current_price DESC 
        LIMIT 1
    )
    WHERE ci.ib_lower_bound IS NOT NULL
)

SELECT *
FROM final_summary
WHERE return_rate IS NOT NULL
ORDER BY return_rate DESC
LIMIT 10;
