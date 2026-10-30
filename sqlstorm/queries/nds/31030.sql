
WITH  sales_data AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_sold_date_sk DESC) AS rn
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 20200101 AND 20201231
),
daily_profit AS (
    SELECT 
        d.d_date,
        SUM(sd.ss_net_profit) AS total_profit,
        COUNT(sd.ss_item_sk) AS total_sales
    FROM sales_data sd
    JOIN date_dim d ON sd.ss_sold_date_sk = d.d_date_sk
    WHERE sd.rn = 1 
    GROUP BY d.d_date
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(s.ss_net_profit) AS total_spent
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_id
    ORDER BY total_spent DESC
    LIMIT 10
),
return_summary AS (
    SELECT
        r.sr_reason_sk,
        SUM(r.sr_return_quantity) AS total_returns,
        SUM(r.sr_return_amt_inc_tax) AS total_refund
    FROM store_returns r
    WHERE r.sr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY r.sr_reason_sk
)

SELECT 
    dd.d_date,
    dd.total_profit,
    dd.total_sales,
    tc.c_customer_id,
    tc.total_spent,
    rs.total_returns,
    rs.total_refund
FROM daily_profit dd
JOIN top_customers tc ON dd.total_profit > 5000
LEFT JOIN return_summary rs ON rs.total_returns > 100
WHERE dd.d_date IN (SELECT d_date FROM date_dim WHERE d_holiday = 'Y')
ORDER BY dd.d_date DESC, tc.total_spent DESC;
