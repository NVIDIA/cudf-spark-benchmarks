
WITH customer_returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_web_return_amount,
        COUNT(wr_return_quantity) AS total_web_returns,
        MAX(wr_returned_date_sk) AS last_return_date
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
store_returns_agg AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_store_return_amount,
        COUNT(sr_return_quantity) AS total_store_returns,
        MAX(sr_returned_date_sk) AS last_store_return_date
    FROM store_returns
    GROUP BY sr_customer_sk
),
combined_returns AS (
    SELECT 
        COALESCE(cwr.wr_returning_customer_sk, sra.sr_customer_sk) AS customer_sk,
        COALESCE(total_web_return_amount, 0) AS total_web_return_amount,
        COALESCE(total_store_return_amount, 0) AS total_store_return_amount,
        COALESCE(total_web_returns, 0) AS total_web_returns,
        COALESCE(total_store_returns, 0) AS total_store_returns,
        CASE 
            WHEN COALESCE(total_web_return_amount, 0) > COALESCE(total_store_return_amount, 0) THEN 'Web'
            ELSE 'Store'
        END AS preferred_return_channel
    FROM customer_returns cwr
    FULL OUTER JOIN store_returns_agg sra 
    ON cwr.wr_returning_customer_sk = sra.sr_customer_sk
),
active_customers AS (
    SELECT 
        DISTINCT c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sales_price > 50
),
final_benchmark AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_first_name,
        ac.c_last_name,
        ac.c_email_address,
        cb.total_web_return_amount,
        cb.total_store_return_amount,
        cb.total_web_returns,
        cb.total_store_returns,
        cb.preferred_return_channel,
        DENSE_RANK() OVER (ORDER BY (cb.total_web_return_amount + cb.total_store_return_amount) DESC) AS return_rank
    FROM active_customers ac
    LEFT JOIN combined_returns cb ON ac.c_customer_sk = cb.customer_sk
)
SELECT 
    fb.c_customer_sk,
    fb.c_first_name,
    fb.c_last_name,
    fb.c_email_address,
    fb.total_web_return_amount,
    fb.total_store_return_amount,
    fb.total_web_returns,
    fb.total_store_returns,
    fb.preferred_return_channel,
    fb.return_rank
FROM final_benchmark fb
WHERE fb.return_rank <= 50
ORDER BY fb.return_rank;
