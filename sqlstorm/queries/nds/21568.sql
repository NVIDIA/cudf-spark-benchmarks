
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_info AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
final_stats AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.purchase_estimate,
        COALESCE(si.total_net_profit, 0) AS total_net_profit,
        COALESCE(ri.total_net_loss, 0) AS total_net_loss,
        si.order_count,
        ri.return_count,
        (COALESCE(si.total_net_profit, 0) - COALESCE(ri.total_net_loss, 0)) AS net_gain,
        CASE 
            WHEN (COALESCE(si.total_net_profit, 0) - COALESCE(ri.total_net_loss, 0)) > 0 THEN 'Profitable'
            WHEN (COALESCE(si.total_net_profit, 0) - COALESCE(ri.total_net_loss, 0)) < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profitability_status,
        ci.gender_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN 
        returns_info ri ON ci.c_customer_sk = ri.sr_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN gender_rank = 1 THEN 'Top Purchaser'
        ELSE 'Regular Purchaser'
    END AS customer_classification
FROM 
    final_stats
WHERE 
    net_gain > 100 OR (purchase_estimate < 300 AND profitability_status = 'Loss')
ORDER BY 
    total_net_profit DESC,
    net_gain DESC
LIMIT 100;
