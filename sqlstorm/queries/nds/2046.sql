
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(cr.total_returned_amount) DESC) AS return_rank
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cr.sr_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    tc.sr_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    ss.total_orders,
    ss.total_sales,
    ss.total_coupons,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN ss.total_sales > 0 THEN (COALESCE(cr.total_returned_quantity, 0) * 100.0 / NULLIF(ss.total_orders, 0)) 
        ELSE 0 
    END AS percentage_returned
FROM TopCustomers tc
LEFT JOIN SalesSummary ss ON tc.sr_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN CustomerReturns cr ON tc.sr_customer_sk = cr.sr_customer_sk
WHERE tc.return_rank <= 5
ORDER BY total_returned_amount DESC;
