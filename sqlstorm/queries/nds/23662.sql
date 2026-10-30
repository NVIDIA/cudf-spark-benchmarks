
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerPurchases AS (
    SELECT 
        ws_bill_customer_sk,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS purchase_rank,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
PromotionsUsed AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_promo_sk) AS promo_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    COALESCE(cp.total_profit, 0) AS total_profit,
    COALESCE(pu.promo_count, 0) AS promo_count,
    CASE 
        WHEN rc.rank <= 5 THEN 'Top 5 Gender Purchasers'
        ELSE 'Other Purchasers'
    END AS purchaser_category
FROM 
    RankedCustomers rc
LEFT JOIN 
    CustomerPurchases cp ON rc.c_customer_sk = cp.ws_bill_customer_sk
LEFT JOIN 
    PromotionsUsed pu ON rc.c_customer_sk = pu.ws_bill_customer_sk
WHERE 
    (rc.cd_marital_status = 'M' OR rc.cd_marital_status IS NULL)
    AND rc.cd_purchase_estimate IS NOT NULL
    AND (rc.cd_gender = 'F' OR rc.cd_gender IS NULL)
ORDER BY 
    total_profit DESC,
    rc.rank;
