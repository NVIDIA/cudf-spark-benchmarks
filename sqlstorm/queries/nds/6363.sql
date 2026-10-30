
WITH sales_data AS (
    SELECT 
        ws_bill_cdemo_sk AS demographic_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_bill_cdemo_sk
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
top_demographics AS (
    SELECT 
        d.demographic_id,
        d.total_sales,
        d.total_orders,
        d.average_profit,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_education_status,
        dem.cd_credit_rating,
        dem.cd_dep_count
    FROM 
        sales_data d
    JOIN 
        demographics dem ON d.demographic_id = dem.cd_demo_sk
    WHERE 
        d.total_sales > (SELECT AVG(total_sales) FROM sales_data)
    ORDER BY 
        d.average_profit DESC
    LIMIT 10
)
SELECT 
    td.demographic_id,
    td.total_sales,
    td.total_orders,
    td.average_profit,
    td.cd_gender,
    td.cd_marital_status,
    td.cd_education_status,
    td.cd_credit_rating,
    td.cd_dep_count
FROM 
    top_demographics td
JOIN 
    customer c ON c.c_current_cdemo_sk = td.demographic_id
WHERE 
    c.c_birth_year BETWEEN 1970 AND 1990
ORDER BY 
    td.total_sales DESC;
