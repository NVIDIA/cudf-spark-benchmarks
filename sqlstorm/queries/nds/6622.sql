
WITH Ranked_Sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
Frequent_Customers AS (
    SELECT 
        c_customer_sk,
        COUNT(*) AS number_of_orders,
        avg(cd_dep_count) AS avg_dependents,
        MAX(cd_credit_rating) AS max_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        web_sales ON c_customer_sk = ws_bill_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rc.ws_bill_customer_sk,
    COUNT(DISTINCT rc.ws_item_sk) AS unique_items_purchased,
    MAX(rc.total_sales) AS highest_single_item_sales,
    fc.number_of_orders,
    fc.avg_dependents,
    fc.max_credit_rating
FROM 
    Ranked_Sales rc
JOIN 
    Frequent_Customers fc ON rc.ws_bill_customer_sk = fc.c_customer_sk
WHERE 
    rc.rank_sales <= 3
GROUP BY 
    rc.ws_bill_customer_sk, fc.number_of_orders, fc.avg_dependents, fc.max_credit_rating
ORDER BY 
    highest_single_item_sales DESC;
