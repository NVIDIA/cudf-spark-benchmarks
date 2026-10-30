
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cr.total_returns,
        cr.total_return_amt,
        cr.total_return_tax
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
        AND cd.cd_marital_status = 'M'
),
HighValueReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_ext_sales_price > 500
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
FinalReport AS (
    SELECT 
        tc.c_customer_id,
        COALESCE(tc.total_returns, 0) AS total_returns,
        COALESCE(tc.total_return_amt, 0) AS total_return_amt,
        COALESCE(tc.total_return_tax, 0) AS total_return_tax,
        hv.total_sales,
        hv.avg_net_profit
    FROM 
        TopCustomers tc
    LEFT JOIN 
        HighValueReturns hv ON tc.c_customer_id = hv.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.total_returns,
    fr.total_return_amt,
    fr.total_return_tax,
    fr.total_sales,
    CASE 
        WHEN fr.total_sales IS NOT NULL AND fr.total_sales > 0 
        THEN ROUND(fr.total_return_amt / fr.total_sales * 100, 2)
        ELSE NULL
    END AS return_percentage,
    fr.avg_net_profit
FROM 
    FinalReport fr
ORDER BY 
    fr.total_returns DESC,
    fr.total_sales DESC
LIMIT 100;
