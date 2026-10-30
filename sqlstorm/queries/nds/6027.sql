
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.order_count,
        r.ws_bill_customer_sk
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.sales_rank <= 100
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS demographic_count
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.ws_bill_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.demographic_count,
    AVG(tc.total_sales) AS avg_sales_per_customer
FROM 
    CustomerDemographics cd
JOIN 
    TopCustomers tc ON cd.demographic_count = tc.total_sales
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.demographic_count
ORDER BY 
    avg_sales_per_customer DESC;
