
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_ticket_number,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0 
    GROUP BY sr_returned_date_sk, sr_return_time_sk, sr_item_sk, sr_customer_sk, sr_ticket_number
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(COUNT(DISTINCT cr.sr_item_sk), 0) AS total_unique_items_returned,
        SUM(cr.total_return_amt) AS total_return_amount
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cr.rn = 1
    GROUP BY cr.sr_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    tc.sr_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_unique_items_returned,
    CASE 
        WHEN tc.total_return_amount IS NULL THEN 'No Returns'
        WHEN tc.total_return_amount < 100 THEN 'Low Return Amount'
        WHEN tc.total_return_amount BETWEEN 100 AND 500 THEN 'Moderate Return Amount'
        ELSE 'High Return Amount'
    END AS return_amount_category,
    RANK() OVER (ORDER BY tc.total_return_amount DESC) AS return_rank
FROM TopCustomers tc
LEFT JOIN income_band ib ON (tc.total_return_amount >= ib.ib_lower_bound AND tc.total_return_amount <= ib.ib_upper_bound)
WHERE ib.ib_income_band_sk IS NULL OR ib.ib_income_band_sk = (
    SELECT MIN(ib_inner.ib_income_band_sk)
    FROM income_band ib_inner 
    WHERE tc.total_return_amount BETWEEN ib_inner.ib_lower_bound AND ib_inner.ib_upper_bound
)
ORDER BY tc.total_return_amount DESC, tc.c_last_name ASC;
