
WITH  CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        AVG(wr_return_amt_inc_tax) AS avg_return_value
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT
        cr.wr_returning_customer_sk,
        cr.total_returned,
        cr.avg_return_value,
        cd.cd_gender,
        cd.cd_marital_status
    FROM CustomerReturns cr
    JOIN customer_demographics cd ON cr.wr_returning_customer_sk = cd.cd_demo_sk
    WHERE cr.total_returned > (
        SELECT AVG(total_returned) FROM CustomerReturns
    )
),
CustomerAddresses AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FrequentReturners AS (
    SELECT
        hrc.wr_returning_customer_sk,
        hrc.total_returned,
        ca.ca_city,
        ca.ca_state,
        ca.city_rank,
        LEAD(hrc.total_returned, 1) OVER (PARTITION BY ca.ca_state ORDER BY hrc.total_returned DESC) AS next_returned
    FROM HighReturnCustomers hrc
    JOIN CustomerAddresses ca ON hrc.wr_returning_customer_sk = ca.c_customer_sk
)
SELECT
    frc.wr_returning_customer_sk,
    frc.total_returned,
    frc.city_rank,
    CASE 
        WHEN frc.next_returned IS NULL THEN 'Last Best Returner'
        WHEN frc.total_returned > frc.next_returned THEN 'Frequent Best Returner'
        ELSE 'Average Returner'
    END AS return_category
FROM FrequentReturners frc
WHERE frc.city_rank <= 5
AND frc.total_returned IS NOT NULL
ORDER BY frc.total_returned DESC;

