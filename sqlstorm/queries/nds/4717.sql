
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 15000 AND 20000
    GROUP BY 
        ws.ws_item_sk
),

CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_ranking
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),

TopSales AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        SalesSummary ss
    JOIN 
        CustomerDetails cd ON cd.gender_ranking <= 10
    WHERE 
        ss.sales_rank = 1
)

SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status_category,
    COALESCE(ROUND(s.total_sales * 0.1, 2), 0) AS estimated_profit
FROM 
    TopSales s
LEFT JOIN 
    CustomerDetails cd ON cd.c_customer_sk IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
ORDER BY 
    s.total_sales DESC;
