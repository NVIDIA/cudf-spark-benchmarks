
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
FilteredSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        COALESCE(c.c_first_name, 'Unknown') AS customer_first_name,
        CASE 
            WHEN c.c_birth_year IS NULL THEN 'Birth year unknown'
            ELSE CAST(EXTRACT(YEAR FROM DATE '2002-10-01') - c.c_birth_year AS STRING)
        END AS customer_age,
        d.d_day_name,
        d.d_month_seq,
        CASE WHEN d.d_holiday = 'Y' THEN 'It''s a holiday!' ELSE 'Just a regular day' END AS holiday_status
    FROM RankedSales r
    LEFT JOIN customer c ON r.ws_order_number = c.c_customer_sk
    JOIN date_dim d ON r.ws_order_number = d.d_date_sk
    WHERE r.rn = 1
),
SalesSummary AS (
    SELECT 
        fs.ws_item_sk,
        SUM(fs.ws_sales_price) AS total_sales,
        COUNT(fs.ws_order_number) AS order_count,
        MAX(fs.customer_age) AS max_customer_age,
        MIN(fs.customer_age) AS min_customer_age,
        STRING_AGG(DISTINCT fs.customer_first_name) AS customer_names
    FROM FilteredSales fs
    GROUP BY fs.ws_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.order_count,
    s.max_customer_age,
    s.min_customer_age,
    REVERSE(s.customer_names) AS reversed_customer_names,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No sales recorded'
        WHEN s.order_count = 0 THEN 'No orders found'
        ELSE 'Sales data available'
    END AS sales_data_status
FROM SalesSummary s
FULL OUTER JOIN item i ON s.ws_item_sk = i.i_item_sk
WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_current_price IS NOT NULL)
  AND (s.total_sales IS NOT NULL OR s.order_count > 10);
