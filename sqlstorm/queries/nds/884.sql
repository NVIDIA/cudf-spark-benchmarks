
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(d.d_year, 0) AS first_purchase_year,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.return_count, 0) AS return_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        cd.cd_purchase_estimate > 50000
)
SELECT
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.total_return_amt,
    hvc.return_count,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
FROM
    HighValueCustomers hvc
LEFT JOIN
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    catalog_sales cs ON hvc.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN
    store_sales ss ON hvc.c_customer_sk = ss.ss_customer_sk
WHERE
    (hvc.total_return_amt < 1000 OR hvc.return_count = 0)
GROUP BY
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.cd_gender, hvc.cd_marital_status, hvc.total_return_amt, hvc.return_count
HAVING
    SUM(ws.ws_net_paid) > 10000
ORDER BY
    hvc.total_return_amt DESC
LIMIT 10;
