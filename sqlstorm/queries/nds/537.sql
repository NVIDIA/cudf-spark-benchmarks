
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000 AND
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M') 
),
AggregatedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_returns,
    hvc.total_return_amount,
    ags.total_spent,
    ags.total_orders,
    ags.avg_order_value
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    AggregatedSales ags ON hvc.c_customer_sk = ags.ws_bill_customer_sk
WHERE 
    (hvc.total_returns > 5 OR ags.total_spent > 500) AND
    (hvc.total_return_amount IS NOT NULL AND hvc.total_return_amount < 2000)
ORDER BY 
    hvc.total_return_amount DESC, 
    ags.avg_order_value DESC
LIMIT 50;
