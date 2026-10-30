
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentPurchases AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        COALESCE(rp.total_spent, 0) AS total_spent,
        COALESCE(rp.total_orders, 0) AS total_orders,
        rc.rank_by_purchase
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        RecentPurchases rp ON rc.c_customer_sk = rp.ws_bill_customer_sk
)
SELECT 
    cb.cd_gender,
    cb.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(cb.total_spent) AS avg_spent,
    AVG(cb.total_orders) AS avg_orders,
    MAX(cb.rank_by_purchase) AS max_purchase_rank
FROM 
    CustomerBenchmark cb
GROUP BY 
    cb.cd_gender, cb.cd_marital_status
HAVING 
    COUNT(*) > 10
ORDER BY 
    cb.cd_gender, cb.cd_marital_status;
