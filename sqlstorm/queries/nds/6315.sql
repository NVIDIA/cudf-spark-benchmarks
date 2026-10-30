
WITH CustomerStats AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_bill_cdemo_sk
),
FinalStats AS (
    SELECT 
        cs.cd_demo_sk,
        cs.cd_gender,
        cs.cd_marital_status,
        coalesce(sd.total_sales, 0) AS total_sales,
        coalesce(sd.total_profit, 0) AS total_profit,
        cs.total_customers,
        cs.total_purchase_estimate,
        cs.avg_dep_count
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesData sd ON cs.cd_demo_sk = sd.ws_bill_cdemo_sk
)
SELECT 
    F.cd_demo_sk,
    F.cd_gender,
    F.cd_marital_status,
    F.total_sales,
    F.total_profit,
    F.total_customers,
    F.total_purchase_estimate,
    F.avg_dep_count,
    RANK() OVER (PARTITION BY F.cd_gender ORDER BY F.total_profit DESC) AS rank_within_gender
FROM 
    FinalStats F
WHERE 
    F.total_sales > 0
ORDER BY 
    F.cd_gender, rank_within_gender;
