
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_quantity DESC) AS rnk
    FROM
        store_returns
    WHERE
        sr_return_quantity IS NOT NULL
),
TopReturns AS (
    SELECT
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        rr.sr_return_quantity,
        rr.sr_return_amt
    FROM
        customer AS customer
    JOIN RankedReturns AS rr ON customer.c_customer_sk = rr.sr_customer_sk
    WHERE
        rr.rnk = 1
),
IncomeStatistics AS (
    SELECT
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        household_demographics AS h
    LEFT JOIN customer AS c ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        h.hd_buy_potential IS NOT NULL
    GROUP BY
        h.hd_income_band_sk
    ORDER BY
        h.hd_income_band_sk
),
ReturnStats AS (
    SELECT
        ir.hd_income_band_sk AS income_band,
        SUM(tr.sr_return_quantity) AS total_return_quantity,
        SUM(tr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT tr.sr_ticket_number) AS return_count
    FROM
        IncomeStatistics AS ir
    JOIN store_returns AS tr ON ir.hd_income_band_sk = tr.sr_cdemo_sk
    GROUP BY
        ir.hd_income_band_sk
),
FinalStats AS (
    SELECT
        r.income_band,
        r.total_return_quantity,
        r.total_return_amt,
        CASE
            WHEN r.return_count = 0 THEN NULL
            ELSE r.total_return_amt / r.return_count
        END AS avg_return_amt
    FROM
        ReturnStats AS r
)
SELECT
    f.income_band,
    f.total_return_quantity,
    f.total_return_amt,
    COALESCE(f.avg_return_amt, 0) AS avg_return_amt,
    CASE 
        WHEN f.total_return_quantity IS NULL THEN 'No Returns'
        WHEN f.total_return_quantity > 100 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_category,
    ROW_NUMBER() OVER (ORDER BY f.total_return_amt DESC) AS rank
FROM
    FinalStats AS f
LEFT JOIN promotion AS p ON p.p_discount_active = 'Y' 
WHERE
    (f.total_return_amt IS NULL OR f.total_return_amt > 500)
    AND (SELECT COUNT(*) FROM customer_address WHERE ca_city IS NULL) < 5
ORDER BY
    return_category, f.total_return_amt DESC;
