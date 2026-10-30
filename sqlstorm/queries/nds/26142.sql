WITH AddressCounts AS (
    SELECT ca_state, COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_state
    HAVING COUNT(*) > 100
),
TrendData AS (
    SELECT d_year, d_month_seq, d_day_name, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE ws_net_paid > 0
    GROUP BY d_year, d_month_seq, d_day_name
),
CombinedData AS (
    SELECT 
        ac.ca_state,
        td.d_year,
        td.d_month_seq,
        td.d_day_name,
        ac.address_count,
        td.total_sales
    FROM AddressCounts ac
    JOIN TrendData td ON td.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
    ORDER BY ac.ca_state, td.d_month_seq
)
SELECT 
    ca_state,
    d_year,
    d_month_seq,
    d_day_name,
    address_count,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
FROM CombinedData
WHERE total_sales IS NOT NULL
ORDER BY ca_state, d_month_seq;