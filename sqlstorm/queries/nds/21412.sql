
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1970
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ss.total_orders,
        ss.total_spent,
        CASE 
            WHEN ss.total_spent IS NULL THEN 'No Purchases'
            WHEN ss.total_spent > 1000 THEN 'High Spender'
            ELSE 'Regular Spender' 
        END AS customer_segment
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    cs.customer_segment,
    CASE 
        WHEN cs.customer_segment = 'High Spender' THEN 'Promote Premium Products'
        WHEN cs.customer_segment = 'Regular Spender' AND cs.total_orders > 5 THEN 'Loyal Customer'
        ELSE 'Target with Discounts' 
    END AS marketing_strategy
FROM 
    CustomerSales cs
WHERE 
    cs.total_orders IS NOT NULL OR cs.customer_segment = 'No Purchases'
ORDER BY 
    cs.total_spent DESC NULLS LAST
LIMIT 10 OFFSET 5;
