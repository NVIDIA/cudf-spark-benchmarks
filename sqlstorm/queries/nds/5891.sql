
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
Promotions AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_promo_sk) AS total_promotions_used
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
HighReturnCustomers AS (
    SELECT
        c.c_customer_id,
        cr.total_return_amount,
        cr.total_returns,
        p.total_promotions_used
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN Promotions p ON c.c_customer_sk = p.ws_bill_customer_sk
    WHERE cr.total_return_amount > (
        SELECT AVG(total_return_amount) FROM CustomerReturns
    )
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    hrc.total_return_amount,
    hrc.total_returns,
    COALESCE(hrc.total_promotions_used, 0) AS total_promotions_used
FROM HighReturnCustomers hrc
JOIN customer c ON hrc.c_customer_id = c.c_customer_id
ORDER BY hrc.total_return_amount DESC, hrc.total_returns DESC
LIMIT 100;
