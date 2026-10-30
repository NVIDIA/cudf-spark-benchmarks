
WITH CustomerReturns AS (
    SELECT 
        sr_cdemo_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_cdemo_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_cdemo_sk
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
DemographicAnalysis AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cr.total_returns, 0) AS returns,
        COALESCE(cr.total_return_amount, 0) AS return_amount,
        COALESCE(sd.total_sales, 0) AS sales,
        COALESCE(sd.total_orders, 0) AS orders,
        CASE 
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'Returning Customer'
            ELSE 'New Customer'
        END AS customer_type
    FROM 
        customer_demographics cd
    LEFT JOIN CustomerReturns cr ON cd.cd_demo_sk = cr.sr_cdemo_sk
    LEFT JOIN SalesData sd ON cd.cd_demo_sk = sd.ws_bill_cdemo_sk
)
SELECT 
    da.cd_demo_sk,
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    da.returns,
    da.return_amount,
    da.sales,
    da.orders,
    da.customer_type,
    ROW_NUMBER() OVER (ORDER BY da.return_amount DESC) AS ranked_by_returns,
    RANK() OVER (ORDER BY da.sales DESC) AS rank_by_sales
FROM 
    DemographicAnalysis da
WHERE 
    (da.return_amount > 100 OR da.sales > 500) 
    AND NOT EXISTS (
        SELECT 1 
        FROM customer cu 
        WHERE cu.c_current_cdemo_sk = da.cd_demo_sk 
        AND cu.c_first_name IS NULL
    )
ORDER BY 
    da.returns DESC NULLS LAST, 
    da.return_amount ASC;
