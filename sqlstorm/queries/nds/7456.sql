
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_bill_cdemo_sk
), 
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_dep_count
    FROM 
        customer_demographics
), 
merged_data AS (
    SELECT 
        ss.customer_demo_sk, 
        d.cd_gender, 
        d.cd_marital_status, 
        d.cd_education_status, 
        d.cd_purchase_estimate, 
        d.cd_dep_count, 
        ss.total_sales, 
        ss.order_count, 
        ss.avg_net_profit
    FROM 
        sales_summary ss
    JOIN 
        demographics d ON ss.customer_demo_sk = d.cd_demo_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(customer_demo_sk) AS customer_count,
    SUM(total_sales) AS total_sales,
    AVG(avg_net_profit) AS average_profit,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    merged_data
GROUP BY 
    cd_gender, 
    cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 10;
