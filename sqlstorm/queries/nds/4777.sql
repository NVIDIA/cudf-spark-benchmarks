
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_order_number,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(rs.ws_net_paid) AS total_spent,
        COUNT(rs.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.rank <= 5
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
AverageSpend AS (
    SELECT 
        AVG(total_spent) AS avg_spent
    FROM 
        TopCustomers
),
CustomerInfo AS (
    SELECT 
        cc.c_customer_sk,
        cc.c_first_name,
        cc.c_last_name,
        ca.ca_zip,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'LOW SPENDER'
            ELSE 'HIGH SPENDER'
        END AS spending_category
    FROM 
        TopCustomers cc
    LEFT JOIN 
        customer_address ca ON cc.c_customer_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON cc.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_zip,
    ci.gender,
    ci.marital_status,
    ci.spending_category,
    ts.total_spent,
    avg.avg_spent
FROM
    CustomerInfo ci
JOIN 
    TopCustomers ts ON ci.c_customer_sk = ts.c_customer_sk
JOIN 
    AverageSpend avg ON 1=1
WHERE 
    ts.total_spent > avg.avg_spent
ORDER BY 
    ts.total_spent DESC
LIMIT 10;
