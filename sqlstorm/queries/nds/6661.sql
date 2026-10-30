
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returned_items,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    WHERE
        sr_returned_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM
        customer_demographics
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cr.total_returned_items,
        cr.total_return_amount
    FROM
        customer AS c
    JOIN
        CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        cr.total_return_amount > (SELECT AVG(total_return_amount) FROM CustomerReturns)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    hvc.total_returned_items,
    hvc.total_return_amount,
    COUNT(ws.ws_order_number) AS num_orders,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.cd_gender, hvc.cd_marital_status, hvc.cd_purchase_estimate, hvc.total_returned_items, hvc.total_return_amount
ORDER BY 
    total_sales DESC
LIMIT 100;
