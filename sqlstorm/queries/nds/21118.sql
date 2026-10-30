
WITH RankedReturns AS (
    SELECT
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr_order_number) AS return_count,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rnk
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk,
        cr_item_sk
),
TopReturns AS (
    SELECT
        r.*,
        COALESCE(CONCAT(c.c_first_name, ' ', c.c_last_name), 'Unknown Customer') AS customer_name
    FROM
        RankedReturns r
    LEFT JOIN
        customer c ON r.cr_returning_customer_sk = c.c_customer_sk
    WHERE
        rnk <= 5
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.ws_item_sk
),
FinalReport AS (
    SELECT
        tr.customer_name,
        tr.cr_item_sk,
        tr.total_return_quantity,
        tr.return_count,
        COALESCE(sd.total_sold, 0) AS total_sold,
        COALESCE(sd.total_profit, 0) AS total_profit,
        CASE
            WHEN COALESCE(sd.total_sold, 0) = 0 THEN NULL
            ELSE (tr.total_return_quantity / CAST(sd.total_sold AS decimal)) * 100
        END AS return_percentage
    FROM
        TopReturns tr
    LEFT JOIN
        SalesData sd ON tr.cr_item_sk = sd.ws_item_sk
)
SELECT
    f.customer_name,
    f.cr_item_sk,
    f.total_return_quantity,
    f.return_count,
    f.total_sold,
    f.total_profit,
    f.return_percentage
FROM
    FinalReport f
WHERE
    f.return_percentage IS NOT NULL
ORDER BY
    f.return_percentage DESC;
