
WITH CustomerReturns AS (
    SELECT 
        coalesce(sr_return_quantity, 0) AS return_quantity,
        coalesce(sr_return_amt_inc_tax, 0) AS return_amount,
        sr_cdemo_sk,
        sr_store_sk,
        sr_ticket_number
    FROM 
        store_returns
    FULL OUTER JOIN 
        store ON sr_store_sk = s_store_sk
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk AS cdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_bill_cdemo_sk
),
ReturnsAnalysis AS (
    SELECT 
        c.c_current_cdemo_sk AS cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN cr.return_quantity > 0 THEN cr.return_quantity ELSE 0 END) AS total_returns,
        SUM(cr.return_amount) AS total_return_amount,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        customer c ON cr.sr_cdemo_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_current_cdemo_sk = sd.cdemo_sk
    GROUP BY 
        c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ra.cdemo_sk,
    ra.cd_gender,
    ra.cd_marital_status,
    ra.total_returns,
    ra.total_return_amount,
    ra.total_sales,
    CASE 
        WHEN ra.total_sales > 0 THEN (ra.total_return_amount * 100.0 / ra.total_sales)
        ELSE NULL 
    END AS return_ratio
FROM 
    ReturnsAnalysis ra
WHERE 
    ra.total_returns > 0
ORDER BY 
    return_ratio DESC
LIMIT 100;
