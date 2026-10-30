
WITH  SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(CASE WHEN ws.ws_order_number IS NOT NULL THEN 1 END) AS promo_sales_count,
        SUM(ws.ws_net_profit) AS total_promo_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name,
    ci.total_spent,
    COALESCE(pd.total_promo_profit, 0) AS promo_profit,
    CASE 
        WHEN ci.total_spent > 1000 THEN 'High Roller'
        WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    Promotions pd ON ci.c_customer_sk = pd.promo_sales_count
WHERE 
    ci.total_spent IS NOT NULL
ORDER BY 
    ci.total_spent DESC
LIMIT 10;
