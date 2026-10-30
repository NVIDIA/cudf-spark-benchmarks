
WITH  SalesHierarchy AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), RankedItems AS (
    SELECT 
        sh.ws_item_sk,
        sh.total_revenue,
        ROW_NUMBER() OVER (ORDER BY sh.total_revenue DESC) AS item_rank
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.total_revenue > (
            SELECT AVG(total_revenue) FROM SalesHierarchy
        )
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_month,
    ci.c_birth_year,
    cd.customer_count,
    cd.married_count,
    cd.avg_purchase_estimate,
    ri.total_revenue,
    CASE 
        WHEN ri.total_revenue > 10000 THEN 'High Value'
        WHEN ri.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer ci
LEFT JOIN 
    RankedItems ri ON ci.c_customer_sk = ri.ws_item_sk
INNER JOIN 
    CustomerDemographics cd ON cd.customer_count > 0
WHERE 
    ci.c_birth_year IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 100
OFFSET 0;
