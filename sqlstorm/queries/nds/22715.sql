
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk AS returning_customer,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CatalogSales AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_quantity) AS total_catalog_sales
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk = (
            SELECT MAX(cs_sold_date_sk) FROM catalog_sales 
            WHERE cs_sold_date_sk <= (
                SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
            )
        )
    GROUP BY
        cs_bill_customer_sk
),
WebSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_profit,
        COUNT(ws_order_number) AS total_web_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_dow IN (5, 6) 
        )
    GROUP BY
        ws_bill_customer_sk
),
IncomeDistribution AS (
    SELECT
        hd_demo_sk,
        ib_income_band_sk,
        COUNT(*) AS num_customers
    FROM
        household_demographics hd
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        hd_demo_sk, ib_income_band_sk
),
FinalReport AS (
    SELECT
        c.c_customer_id,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cs.total_net_profit, 0) + COALESCE(ws.total_web_profit, 0) AS total_profit,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        (COALESCE(cr.total_returned_amount, 0) / NULLIF(cr.total_returns, 0)) * 100 AS return_rate_percentage,
        id.num_customers
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.returning_customer
    LEFT JOIN
        CatalogSales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        WebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        IncomeDistribution id ON c.c_current_cdemo_sk = id.hd_demo_sk
)
SELECT
    f.c_customer_id,
    f.total_returns,
    f.total_profit,
    f.total_returned_quantity,
    f.return_rate_percentage,
    f.num_customers
FROM
    FinalReport f
WHERE
    f.total_profit > 1000 AND 
    (f.total_returns IS NULL OR f.total_returns < 5) 
ORDER BY
    f.return_rate_percentage DESC;
