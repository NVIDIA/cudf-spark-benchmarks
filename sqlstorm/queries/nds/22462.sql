WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
), 
MaxReturns AS (
    SELECT 
        sr_customer_sk, 
        MAX(sr_return_quantity) AS max_return_quantity
    FROM 
        RankedReturns
    WHERE 
        rn <= 5 
    GROUP BY 
        sr_customer_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001) - 30 AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(rr.max_return_quantity, 0) AS max_return_qty,
    rs.total_spent,
    rs.total_orders,
    CASE 
        WHEN rs.total_orders IS NULL THEN 'No Orders'
        WHEN rs.total_orders = 0 THEN 'No Spent'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    CustomerInfo ci
LEFT JOIN 
    MaxReturns rr ON ci.c_customer_sk = rr.sr_customer_sk
LEFT JOIN 
    RecentSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    (ci.cd_gender = 'F' OR ci.cd_gender IS NULL) 
    AND (rr.max_return_quantity IS NOT NULL OR (rs.total_spent > 100 AND rs.total_orders > 2))
ORDER BY 
    max_return_qty DESC,
    rs.total_spent DESC
LIMIT 10;