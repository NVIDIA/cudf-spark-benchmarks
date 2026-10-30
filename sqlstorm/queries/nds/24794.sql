
WITH SalesData AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_revenue,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
),
ReturnsData AS (
    SELECT
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
ItemData AS (
    SELECT
        I.i_item_sk,
        I.i_item_desc,
        COALESCE(SD.total_quantity, 0) AS total_quantity,
        COALESCE(SD.total_revenue, 0) AS total_revenue,
        COALESCE(RD.return_count, 0) AS return_count,
        COALESCE(RD.total_return_amt, 0) AS total_return_amt,
        CASE
            WHEN COALESCE(SD.total_quantity, 0) = 0 THEN NULL
            ELSE (COALESCE(RD.total_return_amt, 0) / NULLIF(COALESCE(SD.total_revenue, 0), 0))
        END AS return_rate
    FROM
        item I
    LEFT JOIN SalesData SD ON I.i_item_sk = SD.ws_item_sk
    LEFT JOIN ReturnsData RD ON I.i_item_sk = RD.wr_item_sk
),
FinalReport AS (
    SELECT
        i_item_sk,
        i_item_desc,
        total_quantity,
        total_revenue,
        return_count,
        total_return_amt,
        return_rate,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        ItemData
)
SELECT
    FR.i_item_sk,
    FR.i_item_desc,
    FR.total_quantity,
    FR.total_revenue,
    FR.return_count,
    FR.total_return_amt,
    FR.return_rate
FROM
    FinalReport FR
WHERE
    FR.return_rate IS NOT NULL
    AND FR.total_revenue > (SELECT AVG(total_revenue) FROM FinalReport WHERE return_count > 0)
ORDER BY
    FR.return_rate DESC, FR.revenue_rank ASC
LIMIT 100;
