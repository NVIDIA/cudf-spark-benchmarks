
WITH RankedWebSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
    )
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date_sk,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date_sk
    HAVING SUM(ws.ws_sales_price) > 1000
),
ReturnedItems AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
FinalReport AS (
    SELECT
        w.ws_item_sk,
        w.ws_order_number,
        COALESCE(r.total_returns, 0) AS total_returns,
        h.total_spent,
        w.ws_sales_price * (1 - (CASE WHEN r.total_returns IS NOT NULL THEN 0.1 ELSE 0 END)) AS adjusted_sales_price
    FROM RankedWebSales w
    LEFT JOIN ReturnedItems r ON w.ws_item_sk = r.wr_item_sk
    LEFT JOIN HighValueCustomers h ON w.ws_order_number = h.c_customer_sk
    WHERE w.sales_rank = 1 AND h.c_customer_sk IS NOT NULL
)
SELECT
    f.ws_item_sk,
    f.ws_order_number,
    f.total_returns,
    f.total_spent,
    f.adjusted_sales_price
FROM FinalReport f
WHERE f.adjusted_sales_price > 50
ORDER BY f.total_spent DESC, f.adjusted_sales_price DESC;
