
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        AVG(sr_return_quantity) AS avg_return_quantity,
        MAX(sr_return_quantity) AS max_return_quantity,
        MIN(sr_return_quantity) AS min_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
StoreSales AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        COUNT(ss_ticket_number) AS total_tickets
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
ReturnStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_value,
        cr.avg_return_quantity,
        cr.max_return_quantity,
        cr.min_return_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_tickets, 0) AS total_tickets,
        CASE 
            WHEN cr.total_returns IS NULL THEN 'No Activity'
            WHEN cr.total_returns > 0 AND ss.total_sales = 0 THEN 'High Returns, No Sales'
            WHEN cr.total_returns > 0 AND ss.total_sales > 0 THEN 'Regular Customer'
            ELSE 'Anomaly'
        END AS return_category
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN
        StoreSales ss ON ss.ss_store_sk = (
            SELECT s_store_sk 
            FROM store 
            WHERE s_number_employees > 5 
            ORDER BY s_store_sk 
            LIMIT 1
        )
),
RankedReturns AS (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.return_category ORDER BY r.total_return_value DESC) AS rank
    FROM 
        ReturnStats r
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_returns,
    r.total_return_value,
    r.avg_return_quantity,
    r.max_return_quantity,
    r.min_return_quantity,
    r.total_sales,
    r.total_tickets,
    r.return_category
FROM 
    RankedReturns r
WHERE 
    r.rank <= 5
ORDER BY 
    r.total_return_value DESC
LIMIT 10 OFFSET 0;
