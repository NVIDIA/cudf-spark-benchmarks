WITH SalesSummary AS (
    SELECT
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_ship_mode_sk,
        ws_bill_cdemo_sk
    FROM web_sales
    GROUP BY ws_ship_mode_sk, ws_bill_cdemo_sk
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        cd_demo_sk
    FROM customer_demographics
    WHERE cd_credit_rating IN ('High', 'Medium') 
),
JoinedData AS (
    SELECT
        sd.*, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM SalesSummary sd
    JOIN CustomerDemographics cd ON sd.ws_bill_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    j.cd_gender,
    j.cd_marital_status,
    COUNT(j.ws_ship_mode_sk) AS order_count,
    AVG(j.total_sales) AS avg_sales_per_order,
    SUM(j.total_profit) AS total_profit
FROM JoinedData j
GROUP BY j.cd_gender, j.cd_marital_status
HAVING COUNT(j.ws_ship_mode_sk) > 10
ORDER BY total_profit DESC
LIMIT 10;