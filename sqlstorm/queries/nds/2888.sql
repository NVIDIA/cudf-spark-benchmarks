
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2459646 
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cu.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_returned_items, 0) AS total_returned_items,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        sd.total_sales,
        sd.order_count
    FROM 
        customer AS cu
    LEFT JOIN 
        customer_demographics AS cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns AS cr ON cu.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData AS sd ON cu.c_customer_sk = sd.customer_sk
    WHERE 
        sd.total_sales > 1000 OR cr.total_returned_items > 0
),
FinalReport AS (
    SELECT 
        hvc.c_customer_id,
        hvc.cd_gender,
        hvc.cd_marital_status,
        hvc.cd_purchase_estimate,
        hvc.total_returned_items,
        hvc.total_return_amount,
        hvc.total_sales,
        hvc.order_count,
        CASE 
            WHEN hvc.total_returned_items > 0 THEN 'High Risk'
            ELSE 'Low Risk'
        END AS customer_risk
    FROM 
        HighValueCustomers AS hvc
)
SELECT 
    hvc.c_customer_id,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    hvc.total_returned_items,
    hvc.total_return_amount,
    hvc.total_sales,
    hvc.order_count,
    CONCAT(hvc.c_customer_id, ' - ', hvc.cd_gender) AS customer_identifier,
    DENSE_RANK() OVER (ORDER BY hvc.total_sales DESC) AS sales_rank
FROM 
    FinalReport AS hvc
ORDER BY 
    hvc.total_sales DESC, hvc.c_customer_id;
