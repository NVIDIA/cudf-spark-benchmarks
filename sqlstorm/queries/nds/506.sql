
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS row_num
    FROM
        web_sales
),
CustomerIncome AS (
    SELECT
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM
        customer c
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        c.c_customer_sk, hd.hd_income_band_sk
),
TotalReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
)
SELECT
    c.c_customer_id,
    COUNT(DISTINCT rs.ws_item_sk) AS total_items_sold,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    SUM(rs.ws_net_profit) AS total_profit,
    ci.customer_count,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount
FROM
    RankedSales rs
JOIN
    customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
JOIN
    CustomerIncome ci ON c.c_customer_sk = ci.c_customer_sk
LEFT JOIN
    TotalReturns tr ON c.c_customer_sk = tr.sr_customer_sk
WHERE
    rs.row_num = 1
GROUP BY
    c.c_customer_id, ci.customer_count, tr.total_return_quantity, tr.total_return_amount
ORDER BY
    total_profit DESC
LIMIT 100;
