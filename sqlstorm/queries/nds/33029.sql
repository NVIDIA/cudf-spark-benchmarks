WITH  SalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) as rank
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
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating
    FROM 
        customer_demographics cd
)
SELECT 
    cte.c_first_name,
    cte.c_last_name,
    cte.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.credit_rating
FROM 
    SalesCTE cte
INNER JOIN 
    customer c ON cte.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cte.total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM 
            SalesCTE
        WHERE 
            rank <= 10
    )
ORDER BY 
    cte.total_sales DESC
LIMIT 100;