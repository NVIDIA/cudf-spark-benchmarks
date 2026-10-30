
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        SUM(ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        sd.total_orders,
        sd.total_revenue,
        sd.total_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND (cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 500)
),
RankedCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS customer_rank
    FROM 
        FilteredCustomers
)

SELECT 
    r.c_first_name || ' ' || r.c_last_name AS customer_full_name,
    r.total_orders,
    r.total_revenue,
    r.total_quantity,
    COALESCE(r.customer_rank, 0) AS customer_rank
FROM 
    RankedCustomers r
WHERE 
    r.total_revenue > 1000
ORDER BY 
    r.total_revenue DESC;

