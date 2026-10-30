
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_marital_status, 
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers AS rc
    WHERE 
        rc.ranking <= 10
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        ss.total_sales,
        ss.order_count
    FROM 
        TopCustomers AS tc
    LEFT JOIN 
        SalesSummary AS ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count
FROM 
    CustomerSales AS cs
ORDER BY 
    total_sales DESC
LIMIT 20;
