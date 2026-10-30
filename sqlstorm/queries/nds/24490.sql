
WITH  CustomerReturnStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax,
        CASE
            WHEN COUNT(sr.sr_item_sk) = 0 THEN 0
            ELSE SUM(sr.sr_return_amt) / COUNT(sr.sr_item_sk)
        END AS avg_return_amt,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(sr.sr_return_amt) DESC) AS rnk
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_returns,
        cs.total_return_amt,
        cs.avg_return_amt
    FROM
        CustomerReturnStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.total_return_amt > (
            SELECT AVG(total_return_amt) FROM CustomerReturnStats
        )
        AND cs.rnk <= 10
),
StoreSales AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS store_total_sales,
        AVG(ss.ss_net_paid) AS avg_sales_per_transaction
    FROM
        store_sales ss
    GROUP BY
        ss.ss_store_sk
),
CustomerSales AS (
    SELECT
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM
        web_sales ws
    GROUP BY
        ws.ws_ship_customer_sk
),
CombinedResults AS (
    SELECT
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        coalesce(ss.store_total_sales, 0) AS store_sales_total,
        coalesce(cs.total_web_sales, 0) AS web_sales_total,
        (coalesce(ss.store_total_sales, 0) + coalesce(cs.total_web_sales, 0)) AS total_sales
    FROM
        HighValueCustomers hvc
    LEFT JOIN StoreSales ss ON hvc.c_customer_sk = ss.ss_store_sk
    LEFT JOIN CustomerSales cs ON hvc.c_customer_sk = cs.ws_ship_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_birth_month,
    c.c_birth_year,
    cr.store_sales_total,
    cr.web_sales_total,
    cr.total_sales,
    DENSE_RANK() OVER (ORDER BY cr.total_sales DESC) as sales_rank,
    CASE 
        WHEN cr.total_sales IS NULL THEN 'No Sales'
        WHEN cr.total_sales = 0 THEN 'Zero Sales'
        ELSE 'Active Sales'
    END AS sales_status
FROM
    CombinedResults cr
JOIN customer c ON cr.c_customer_sk = c.c_customer_sk
WHERE
    (c.c_birth_month IS NOT NULL OR c.c_birth_year IS NOT NULL)
ORDER BY
    cr.total_sales DESC,
    c.c_birth_year DESC,
    c.c_birth_month DESC
LIMIT 50;
