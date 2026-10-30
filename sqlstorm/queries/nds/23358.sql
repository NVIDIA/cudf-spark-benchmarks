
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
frequent_shoppers AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(*) AS total_purchases,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_spent
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
    HAVING 
        COUNT(*) > 3
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        (SELECT COUNT(*) FROM store s WHERE s.s_city = ca.ca_city AND s.s_state = ca.ca_state) as store_count
    FROM 
        customer_address ca
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    fs.total_purchases,
    fs.total_spent,
    ca.store_count,
    (CASE 
        WHEN rc.purchase_rank <= 3 THEN 'Top Purchaser'
        ELSE 'Regular Customer'
    END) AS customer_category,
    COALESCE(ca.ca_city, 'Unknown') AS customer_city,
    COALESCE(ca.store_count, 0) AS store_count
FROM 
    ranked_customers rc
LEFT JOIN 
    frequent_shoppers fs ON rc.c_customer_sk = fs.ws_bill_customer_sk
LEFT JOIN 
    customer_addresses ca ON rc.c_customer_sk = ca.ca_address_sk
WHERE 
    (fs.total_spent > 1000 OR fs.total_purchases IS NULL)
    AND rc.cd_gender IN ('M', 'F')
ORDER BY 
    fs.total_spent DESC, rc.cd_gender, rc.c_customer_id;
