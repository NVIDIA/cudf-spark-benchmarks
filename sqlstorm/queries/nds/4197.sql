
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_bill_cdemo_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452335 AND 2452401
),
CustDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status AS marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CASE 
            WHEN cd_dep_count > 2 THEN 'High Dependency'
            WHEN cd_dep_count BETWEEN 1 AND 2 THEN 'Medium Dependency'
            ELSE 'Low Dependency'
        END AS dependency_level
    FROM 
        customer_demographics
),
TopCustomers AS (
    SELECT 
        sd.ws_bill_customer_sk,
        cd.cd_gender,
        cd.marital_status,
        cd.dependency_level,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        SalesData sd
    JOIN 
        CustDemographics cd ON sd.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_bill_customer_sk, cd.cd_gender, cd.marital_status, cd.dependency_level
),
NextTopCustomers AS (
    SELECT 
        ws_bill_customer_sk, 
        'Second Tier' AS tier,
        cd_gender, 
        marital_status,
        dependency_level,
        total_sales,
        total_profit
    FROM 
        TopCustomers
    WHERE 
        total_sales < (SELECT AVG(total_sales) FROM TopCustomers)
)

SELECT 
    tc.ws_bill_customer_sk,
    tc.cd_gender,
    tc.marital_status,
    tc.dependency_level,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(ntc.total_sales, 0) AS second_tier_sales,
    tc.total_profit,
    COALESCE(ntc.total_profit, 0) AS second_tier_profit
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    NextTopCustomers ntc ON tc.ws_bill_customer_sk = ntc.ws_bill_customer_sk
WHERE 
    (tc.total_sales IS NOT NULL OR ntc.total_sales IS NOT NULL)
ORDER BY 
    total_sales DESC, second_tier_sales DESC;
