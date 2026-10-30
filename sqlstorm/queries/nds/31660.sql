
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS overall_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),

customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

frequent_customers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        MAX(cs.total_sales) AS max_sales
    FROM 
        sales_summary cs
    WHERE 
        cs.sales_rank <= 10
    GROUP BY 
        cs.ws_bill_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.purchase_category,
    cs.total_sales,
    cs.total_orders,
    fs.max_sales,
    CASE 
        WHEN fs.max_sales IS NOT NULL THEN 'Frequent Buyer'
        ELSE 'Regular Buyer'
    END AS customer_type
FROM 
    customer_details cd
LEFT JOIN 
    sales_summary cs ON cd.c_customer_sk = cs.ws_bill_customer_sk
LEFT JOIN 
    frequent_customers fs ON cd.c_customer_sk = fs.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.c_first_name LIKE 'A%'
    AND cd.c_last_name <> 'Smith'
ORDER BY 
    total_sales DESC, 
    cd.c_last_name ASC
LIMIT 50;
