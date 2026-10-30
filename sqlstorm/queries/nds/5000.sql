
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
), 
DemographicData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
PerformanceMetrics AS (
    SELECT 
        dd.ws_bill_customer_sk,
        dd.total_sales,
        dd.total_orders,
        dd.unique_items,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_credit_rating
    FROM 
        SalesData AS dd
    JOIN 
        DemographicData AS d ON dd.ws_bill_customer_sk = d.c_customer_sk
)
SELECT 
    pm.cd_gender,
    pm.cd_marital_status,
    pm.cd_education_status,
    pm.cd_credit_rating,
    AVG(pm.total_sales) AS avg_total_sales,
    AVG(pm.total_orders) AS avg_total_orders,
    AVG(pm.unique_items) AS avg_unique_items
FROM 
    PerformanceMetrics AS pm
GROUP BY 
    pm.cd_gender,
    pm.cd_marital_status,
    pm.cd_education_status,
    pm.cd_credit_rating
ORDER BY 
    avg_total_sales DESC;
