
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM 
        customer_demographics AS cd
    WHERE 
        cd.cd_purchase_estimate > 1000
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales AS cs
    JOIN 
        CustomerDemographics AS cd ON cs.c_customer_sk = cd.cd_demo_sk
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status
FROM 
    TopCustomers AS tc
JOIN 
    date_dim AS dd ON dd.d_date_sk BETWEEN 20220101 AND 20221231
LEFT JOIN 
    promotion AS p ON p.p_promo_sk = tc.total_orders
WHERE 
    dd.d_weekend = 'Y'
    AND p.p_discount_active = 'Y'
ORDER BY 
    tc.total_sales DESC;
