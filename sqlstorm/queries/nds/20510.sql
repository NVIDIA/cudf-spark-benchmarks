
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 100 AND 200
    GROUP BY ws_item_sk
),
HighEarningCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws_net_paid_inc_tax) > 5000
),
SeasonalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_dow IN (1, 7)))
    GROUP BY sr_item_sk
),
FinalMetrics AS (
    SELECT
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        hc.c_first_name,
        hc.c_last_name,
        hc.order_count,
        hc.total_spent,
        COALESCE(s.total_returns, 0) AS total_returns,
        COALESCE(s.return_count, 0) AS return_count
    FROM RankedSales r
    LEFT JOIN HighEarningCustomers hc ON r.ws_item_sk = hc.c_customer_sk
    LEFT JOIN SeasonalReturns s ON r.ws_item_sk = s.sr_item_sk
    WHERE r.rank = 1 OR (hc.order_count > 10 AND hc.total_spent IS NOT NULL)
)
SELECT
    f.ws_item_sk,
    f.total_quantity,
    f.total_net_paid,
    f.c_first_name,
    f.c_last_name,
    f.order_count,
    f.total_spent,
    f.total_returns,
    f.return_count,
    CASE
        WHEN f.order_count IS NULL THEN 'NO ORDERS'
        WHEN f.total_spent > 10000 THEN 'HIGH SPENDER'
        ELSE 'REGULAR CUSTOMER'
    END AS customer_category,
    CONCAT('Item ', f.ws_item_sk, ': ', f.total_net_paid) AS item_description
FROM FinalMetrics f
WHERE f.total_net_paid IS NOT NULL
ORDER BY f.total_net_paid DESC
LIMIT 100;
