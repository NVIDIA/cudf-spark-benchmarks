
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerInterest AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        RankedCustomers
    WHERE 
        rank <= 10
),
Dates AS (
    SELECT 
        d.d_date,
        d.d_year,
        COUNT(ws.ws_order_number) as order_count,
        SUM(ws.ws_net_paid) as total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date, d.d_year
),
SalesData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        d.d_year,
        d.order_count,
        d.total_sales
    FROM 
        CustomerInterest ci
    JOIN 
        Dates d ON ci.cd_purchase_estimate BETWEEN 500 AND 1000
)
SELECT
    cd.cd_gender,
    COUNT(*) AS customer_count,
    SUM(sd.total_sales) AS total_sales,
    AVG(sd.total_sales) AS avg_sales,
    MIN(sd.total_sales) AS min_sales,
    MAX(sd.total_sales) AS max_sales
FROM 
    SalesData sd
JOIN 
    CustomerInterest ci ON sd.full_name = ci.full_name
JOIN 
    customer_demographics cd ON ci.cd_credit_rating = cd.cd_credit_rating
GROUP BY 
    cd.cd_gender
ORDER BY 
    cd.cd_gender;
