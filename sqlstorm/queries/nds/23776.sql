
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopReturningCustomers AS (
    SELECT
        cr.*,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM
        CustomerReturns cr
    JOIN
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        cr.rn <= 10
),
CustomerIncome AS (
    SELECT
        c.c_customer_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer c
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    t.*,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    CASE 
        WHEN ci.ib_lower_bound IS NULL THEN 'Unknown'
        WHEN ci.ib_upper_bound IS NULL THEN 'High Income'
        ELSE CONCAT('Income between ', ci.ib_lower_bound, ' and ', ci.ib_upper_bound)
    END AS income_description,
    ROW_NUMBER() OVER (PARTITION BY t.sr_customer_sk ORDER BY t.total_returned_qty DESC) AS rank_return
FROM
    TopReturningCustomers t
LEFT JOIN
    CustomerIncome ci ON t.sr_customer_sk = ci.c_customer_sk
ORDER BY
    t.total_returned_amt DESC,
    rank_return;
