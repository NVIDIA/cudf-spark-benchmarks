
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        cs.sr_customer_sk AS customer_sk,
        cs.total_returns,
        ss.num_orders,
        ss.total_spent
    FROM
        CustomerReturns cs
    JOIN
        SalesSummary ss ON cs.sr_customer_sk = ss.customer_sk
    WHERE
        cs.total_returns > 0 AND ss.num_orders > 5
),
ItemRank AS (
    SELECT
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(tc.total_returns, 0) AS total_returns,
    COALESCE(tc.num_orders, 0) AS num_orders,
    COALESCE(tc.total_spent, 0) AS total_spent,
    ir.ws_item_sk
FROM
    customer c
LEFT JOIN
    TopCustomers tc ON c.c_customer_sk = tc.customer_sk
LEFT JOIN
    ItemRank ir ON ir.rank = 1
WHERE
    c.c_birth_year < 1980 
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_last_name LIKE 'S%')
ORDER BY 
    total_spent DESC, total_returns DESC
LIMIT 100;
