
WITH CustomerReturns AS (
    SELECT
        COALESCE(SR.sr_customer_sk, WR.wr_returning_customer_sk) AS customer_sk,
        SUM(SR.sr_return_quantity) AS total_returned_quantity,
        SUM(SR.sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT WR.wr_order_number) AS web_return_count
    FROM
        store_returns SR
    FULL OUTER JOIN
        web_returns WR ON SR.sr_item_sk = WR.wr_item_sk
    GROUP BY
        COALESCE(SR.sr_customer_sk, WR.wr_returning_customer_sk)
),
SalesSummary AS (
    SELECT
        WS.ws_bill_customer_sk AS customer_sk,
        SUM(WS.ws_quantity) AS total_sales_quantity,
        SUM(WS.ws_net_profit) AS total_sales_profit
    FROM
        web_sales WS
    GROUP BY
        WS.ws_bill_customer_sk
),
CustomerPerformance AS (
    SELECT
        C.c_customer_sk,
        C.c_first_name,
        C.c_last_name,
        COALESCE(CR.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(CR.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(SS.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(SS.total_sales_profit, 0) AS total_sales_profit,
        CASE
            WHEN COALESCE(SS.total_sales_profit, 0) = 0 THEN 0
            ELSE ROUND(COALESCE(CR.total_returned_amount / SS.total_sales_profit, 0) * 100, 2)
        END AS return_rate_percentage
    FROM
        customer C
    LEFT JOIN
        CustomerReturns CR ON C.c_customer_sk = CR.customer_sk
    LEFT JOIN
        SalesSummary SS ON C.c_customer_sk = SS.customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    cp.total_returned_quantity,
    cp.total_returned_amount,
    cp.total_sales_quantity,
    cp.total_sales_profit,
    cp.return_rate_percentage
FROM
    CustomerPerformance cp
JOIN
    customer c ON cp.c_customer_sk = c.c_customer_sk
WHERE
    cp.return_rate_percentage > 10
ORDER BY
    cp.return_rate_percentage DESC
LIMIT 100;
