
WITH RankedSales AS (
    SELECT
        s.ss_store_sk,
        s.ss_ticket_number,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ss_store_sk ORDER BY SUM(s.ss_net_profit) DESC) AS rank
    FROM
        store_sales s
    WHERE
        s.ss_sold_date_sk >= (
            SELECT MIN(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_current_year = 'Y'
        ) AND
        s.ss_sold_date_sk <= (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_current_year = 'Y'
        )
    GROUP BY
        s.ss_store_sk, s.ss_ticket_number
), StoreProfits AS (
    SELECT 
        sr.ss_store_sk,
        SUM(sr.total_profit) AS total_store_profit,
        COUNT(DISTINCT sr.ss_ticket_number) AS unique_transactions
    FROM 
        RankedSales sr
    WHERE
        sr.rank <= 5
    GROUP BY 
        sr.ss_store_sk
), CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_refunded_customer_sk IS NOT NULL
        AND cr.cr_return_quantity > 0
    GROUP BY 
        cr.cr_returning_customer_sk
), CustomerReturnsSummary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.return_count, 0) AS return_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cs.c_customer_sk,
    cs.total_return_quantity,
    cs.return_count,
    sp.total_store_profit,
    sp.unique_transactions,
    CASE
        WHEN sp.total_store_profit IS NULL THEN 'No Profit Data'
        ELSE 'Profit Data Available'
    END AS profit_status
FROM 
    CustomerReturnsSummary cs
LEFT JOIN 
    StoreProfits sp ON cs.c_customer_sk = sp.ss_store_sk
WHERE 
    cs.return_count > 0
ORDER BY 
    total_return_quantity DESC, 
    total_store_profit DESC NULLS LAST
LIMIT 50;
