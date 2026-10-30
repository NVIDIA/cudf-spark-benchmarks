
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS overall_rank,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 1000
),
FrequentReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk, 
        hvc.c_first_name, 
        hvc.c_last_name, 
        hvc.cd_gender,
        hvc.cd_marital_status, 
        COALESCE(f.return_count, 0) AS return_count, 
        COALESCE(f.total_returned_amt, 0) AS total_returned_amt,
        hvc.total_sales,
        hvc.overall_rank
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        FrequentReturns f ON hvc.c_customer_sk = f.sr_customer_sk
)
SELECT 
    fr.c_customer_sk, 
    fr.c_first_name, 
    fr.c_last_name, 
    fr.cd_gender,
    fr.cd_marital_status, 
    fr.return_count, 
    fr.total_returned_amt,
    fr.total_sales,
    CASE 
        WHEN fr.return_count > 5 THEN 'High Returner'
        ELSE 'Standard Customer'
    END AS customer_category
FROM 
    FinalReport fr
WHERE 
    fr.total_returned_amt < fr.total_sales * 0.1
ORDER BY 
    fr.total_sales DESC, 
    fr.return_count DESC;
