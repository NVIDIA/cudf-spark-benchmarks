
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status IS NOT NULL 
        AND cd.cd_credit_rating IS NOT NULL
)

SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    CASE 
        WHEN hvc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    HighValueCustomers hvc
JOIN 
    CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL) 
ORDER BY 
    hvc.total_web_sales DESC;
