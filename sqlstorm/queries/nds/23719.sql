
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        sr_return_quantity,
        sr_reason_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM
        store_returns
),
CustomerWithReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity,
        CASE
            WHEN COUNT(sr.sr_return_quantity) > 0 THEN 'HAS RETURNS'
            ELSE 'NO RETURNS'
        END AS return_status
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT
        cwr.c_customer_sk,
        cwr.c_first_name,
        cwr.c_last_name,
        cwr.total_return_quantity,
        (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_demo_sk = cwr.c_customer_sk) AS demo_count,
        CASE
            WHEN (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_demo_sk = cwr.c_customer_sk) > 0 THEN 'DIVERSE DEMO'
            ELSE 'UNKNOWN DEMO'
        END AS demo_status
    FROM
        CustomerWithReturns cwr
    WHERE
        cwr.total_return_quantity > (
            SELECT AVG(total_return_quantity) FROM CustomerWithReturns
        )
)
SELECT
    hw.w_warehouse_name,
    COUNT(DISTINCT hr.c_customer_sk) AS customer_count,
    SUM(COALESCE(r.sr_return_quantity, 0)) AS total_returns,
    SUM(CASE WHEN hr.demo_status = 'DIVERSE DEMO' THEN 1 ELSE 0 END) AS diverse_demo_customers,
    COUNT(*) OVER (PARTITION BY hw.w_warehouse_name) AS warehouse_partition_count
FROM
    warehouse hw
LEFT JOIN
    store_sales ss ON ss.ss_store_sk = hw.w_warehouse_sk
LEFT JOIN
    HighValueCustomers hr ON hr.c_customer_sk = ss.ss_customer_sk
LEFT JOIN
    store_returns r ON r.sr_customer_sk = hr.c_customer_sk
WHERE
    hw.w_warehouse_name IS NOT NULL AND
    hr.demo_status IS NOT NULL
GROUP BY
    hw.w_warehouse_name
HAVING
    COUNT(DISTINCT hr.c_customer_sk) > 5
ORDER BY
    total_returns DESC;
