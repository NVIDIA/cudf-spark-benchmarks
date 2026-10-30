
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > 500
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_orders,
        cs.last_order_date,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    r.total_web_sales,
    r.total_orders,
    r.last_order_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    RankedSales r
JOIN 
    customer c ON r.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    r.total_orders > 5
    AND (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
ORDER BY 
    r.total_web_sales DESC
LIMIT 10;
