
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales) FROM CustomerSales
        )
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.cd_purchase_estimate,
    COALESCE(tc.total_sales, 0) AS total_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No sales'
        ELSE 'Sales exist'
    END AS sales_status
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_purchase_estimate > 50000
ORDER BY 
    tc.total_sales DESC
LIMIT 10;
