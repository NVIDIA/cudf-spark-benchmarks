
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS unique_orders
    FROM
        catalog_returns
    WHERE
        cr_return_quantity > 0
    GROUP BY
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS unique_orders
    FROM
        web_returns
    WHERE
        wr_return_quantity IS NOT NULL AND wr_return_quantity <> 0
    GROUP BY
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT
        COALESCE(cr.cr_returning_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_returned, 0) + COALESCE(wr.total_returned, 0) AS overall_returned,
        COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_return_amount, 0) AS overall_return_amount,
        COALESCE(cr.unique_orders, 0) + COALESCE(wr.unique_orders, 0) AS total_unique_orders
    FROM
        CustomerReturns cr
    FULL OUTER JOIN
        WebReturns wr ON cr.cr_returning_customer_sk = wr.wr_returning_customer_sk
),
RankedReturns AS (
    SELECT
        customer_sk,
        overall_returned,
        overall_return_amount,
        total_unique_orders,
        RANK() OVER (ORDER BY overall_return_amount DESC) AS return_rank
    FROM
        CombinedReturns
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.overall_returned,
    r.overall_return_amount,
    r.total_unique_orders,
    r.return_rank
FROM
    RankedReturns r
JOIN
    customer c ON r.customer_sk = c.c_customer_sk
WHERE
    r.return_rank <= 10
    AND r.overall_returned > (SELECT AVG(overall_returned) FROM CombinedReturns)
ORDER BY
    r.return_rank;
