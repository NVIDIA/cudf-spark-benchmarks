
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
TopItems AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        sales.total_quantity,
        sales.total_profit
    FROM 
        item
    JOIN 
        SalesData AS sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.total_quantity > (SELECT AVG(total_quantity) FROM SalesData)
    ORDER BY 
        sales.total_profit DESC
    LIMIT 10
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COUNT(DISTINCT ci.cd_demo_sk) AS demographics_count,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_profit
FROM 
    CustomerDemographics AS ci
JOIN 
    TopItems AS ti ON ci.customer_count > 0
GROUP BY 
    ci.cd_gender, ci.cd_marital_status, ci.cd_education_status, ti.i_product_name, ti.total_quantity, ti.total_profit
ORDER BY 
    ti.total_profit DESC;
