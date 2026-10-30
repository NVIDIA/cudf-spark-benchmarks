
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAggregate AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ra.total_net_profit,
        ra.total_orders
    FROM 
        RankedCustomers rc
    JOIN 
        SalesAggregate ra ON rc.c_customer_sk = ra.ws_bill_customer_sk
    WHERE 
        rc.PurchaseRank <= 10
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_net_profit,
    CASE 
        WHEN hvc.total_net_profit IS NULL THEN 'No Sales'
        ELSE CASE 
            WHEN hvc.total_net_profit > 1000 THEN 'Platinum'
            WHEN hvc.total_net_profit > 500 THEN 'Gold'
            ELSE 'Silver'
        END
    END AS CustomerTier,
    COALESCE(cc.cc_name, 'Not Available') AS CallCenterName
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    call_center cc ON hvc.c_customer_sk = cc.cc_call_center_sk
ORDER BY 
    hvc.total_net_profit DESC;
