
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        MAX(sr_returned_date_sk) AS last_return_date
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebSales AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        AVG(ws_quantity) AS avg_items_per_order
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(cr.total_returned_items, 0) AS returns_count,
        COALESCE(cr.total_returned_amount, 0) AS returns_amount,
        COALESCE(ws.total_orders, 0) AS web_orders_count,
        COALESCE(ws.total_spent, 0) AS total_web_spent,
        COALESCE(ws.avg_items_per_order, 0) AS avg_web_items_order
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN WebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
RankedSales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_web_spent DESC) AS rank_within_gender
    FROM SalesSummary
)
SELECT
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.gender,
    s.returns_count,
    s.returns_amount,
    s.web_orders_count,
    s.total_web_spent,
    s.avg_web_items_order,
    CASE
        WHEN s.rank_within_gender <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS category
FROM RankedSales s
WHERE (s.returns_count = 0 OR s.total_web_spent > 100)
    AND s.web_orders_count > 0
ORDER BY s.gender, s.total_web_spent DESC;
