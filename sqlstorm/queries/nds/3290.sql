WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amt_inc_tax) AS total_return_amt
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_credit_rating IS NOT NULL
),
TopCustomers AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cr.total_return_quantity,
        cr.total_return_amt,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS row_num
    FROM CustomerDetails cd
    JOIN CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
    WHERE cr.total_return_quantity > 0
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_return_quantity,
    tc.total_return_amt,
    CASE 
        WHEN tc.total_return_amt > 1000 THEN 'High Value'
        WHEN tc.total_return_amt BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS return_value_category
FROM TopCustomers tc
WHERE tc.row_num <= 10
ORDER BY tc.total_return_amt DESC;