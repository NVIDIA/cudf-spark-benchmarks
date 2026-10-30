
WITH detailed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        COUNT(ca_county) OVER (PARTITION BY ca_state) AS county_count
    FROM customer_address
),
gender_income_analysis AS (
    SELECT 
        cd_gender,
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', CAST(ib_lower_bound AS STRING), ' - $', CAST(ib_upper_bound AS STRING))
        END AS income_band,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_demographics 
    JOIN household_demographics ON hd_income_band_sk = cd_demo_sk
    LEFT JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    JOIN customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, ib_lower_bound, ib_upper_bound
),
date_group AS (
    SELECT 
        d_date_sk,
        d_day_name,
        d_month_seq,
        d_year,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales
    FROM date_dim
    JOIN web_sales ON d_date_sk = ws_sold_date_sk
    GROUP BY d_date_sk, d_day_name, d_month_seq, d_year
)
SELECT 
    da.full_address,
    da.ca_city,
    da.ca_state,
    da.ca_zip,
    gia.cd_gender,
    gia.income_band,
    gia.customer_count,
    dg.d_day_name,
    dg.total_sales
FROM detailed_addresses da
JOIN gender_income_analysis gia ON da.ca_state = 'CA'
JOIN date_group dg ON dg.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01')
WHERE da.county_count > 5
ORDER BY gia.customer_count DESC, dg.total_sales DESC
LIMIT 100;
