
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
ProfitableCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        rs.total_net_profit
    FROM 
        CustomerInfo ci
    INNER JOIN 
        RankedSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.profit_rank = 1
)
SELECT 
    pc.c_customer_sk,
    pc.c_first_name,
    pc.c_last_name,
    pc.cd_gender,
    pc.cd_marital_status,
    pc.cd_purchase_estimate,
    pc.total_net_profit,
    (SELECT COUNT(*) FROM web_sales WHERE ws_bill_customer_sk = pc.c_customer_sk) AS total_orders,
    (SELECT AVG(ws_net_paid) FROM web_sales WHERE ws_bill_customer_sk = pc.c_customer_sk) AS avg_order_value,
    CASE 
        WHEN pc.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN pc.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    ProfitableCustomers pc
WHERE 
    pc.total_net_profit > (SELECT AVG(total_net_profit) FROM RankedSales)
ORDER BY 
    pc.total_net_profit DESC;
