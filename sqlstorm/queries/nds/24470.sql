
WITH RecursiveCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY COALESCE(SUM(ws.ws_ext_sales_price), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        rcs.c_customer_sk,
        rcs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        RecursiveCustomerSales rcs
    JOIN 
        CustomerDemographics cd ON rcs.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        rcs.sales_rank <= 5
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amt,
    CASE 
        WHEN SUM(sr.sr_return_amt) IS NULL AND SUM(cr.cr_return_amount) IS NULL THEN 'No returns'
        WHEN SUM(sr.sr_return_amt) > SUM(cr.cr_return_amount) THEN 'More store returns'
        WHEN SUM(cr.cr_return_amount) > SUM(sr.sr_return_amt) THEN 'More catalog returns'
        ELSE 'Equal returns'
    END AS return_comparison
FROM 
    TopCustomers tc
LEFT JOIN 
    store_returns sr ON tc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    catalog_returns cr ON tc.c_customer_sk = cr.cr_returning_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.total_sales, tc.cd_gender, tc.cd_marital_status
ORDER BY 
    tc.total_sales DESC;

