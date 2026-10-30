
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        d_year,
        d_month_seq
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2022 AND 2023
    GROUP BY 
        ws_bill_customer_sk, d_year, d_month_seq
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ProfitAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_profit) AS total_profit,
        COUNT(DISTINCT sd.ws_bill_customer_sk) AS customer_count
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    total_profit,
    customer_count,
    total_profit / customer_count AS avg_profit_per_customer
FROM 
    ProfitAnalysis
ORDER BY 
    total_profit DESC;
