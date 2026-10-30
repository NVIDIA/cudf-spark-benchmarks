
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
ProfitDistribution AS (
    SELECT 
        CASE 
            WHEN total_profit > 1000 THEN 'High Profit'
            WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        SalesSummary
    GROUP BY 
        profit_category
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    pd.profit_category,
    COALESCE(SUM(pd.customer_count), 0) AS total_customers
FROM 
    CustomerDemographics cd
LEFT JOIN 
    ProfitDistribution pd ON pd.customer_count > 0
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, pd.profit_category
ORDER BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, pd.profit_category;
