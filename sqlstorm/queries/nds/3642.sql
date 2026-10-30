
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_ship_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items_bought
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status,
    ss.total_spent,
    ss.total_orders,
    ss.unique_items_bought,
    CASE 
        WHEN ss.total_spent IS NULL THEN 'No purchases'
        WHEN ss.total_spent >= 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerRanked cr
LEFT JOIN 
    SalesSummary ss ON cr.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cr.purchase_rank <= 10
    AND (cr.cd_gender IS NOT NULL OR cr.cd_marital_status IS NOT NULL)
ORDER BY 
    ss.total_spent DESC NULLS LAST;
