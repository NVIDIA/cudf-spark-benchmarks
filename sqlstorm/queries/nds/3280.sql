
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerSpend AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_spent
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
AggregateCustomerData AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cs.total_spent, 0) AS total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN
        CustomerSpend cs ON c.c_customer_sk = cs.customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    total_returns,
    total_spent,
    cd_gender,
    cd_marital_status,
    AVG(total_spent) OVER (PARTITION BY cd_gender) AS avg_spent_by_gender,
    SUM(total_returns) OVER (PARTITION BY cd_marital_status) AS total_returns_by_marital_status
FROM
    AggregateCustomerData
WHERE
    total_spent > 0
UNION ALL
SELECT
    total_returns,
    total_spent,
    cd_gender,
    cd_marital_status,
    AVG(total_spent) OVER (PARTITION BY cd_gender) AS avg_spent_by_gender,
    SUM(total_returns) OVER (PARTITION BY cd_marital_status) AS total_returns_by_marital_status
FROM
    AggregateCustomerData
WHERE
    total_spent IS NULL;
