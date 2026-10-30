
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_transaction_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
TopIncomeBands AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(hd.hd_demo_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    ORDER BY 
        customer_count DESC
    LIMIT 5
),
WebSalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.total_orders,
    cs.total_net_profit,
    CASE 
        WHEN cs.total_orders = 0 THEN NULL 
        ELSE cs.total_net_profit / cs.total_orders 
    END AS avg_profit_per_order,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ib.customer_count,
    wsd.total_quantity_sold,
    wsd.total_web_profit
FROM 
    CustomerStats cs
JOIN 
    TopIncomeBands ib ON ib.ib_lower_bound <= cs.cd_purchase_estimate AND ib.ib_upper_bound > cs.cd_purchase_estimate
LEFT JOIN 
    WebSalesDetails wsd ON wsd.ws_item_sk = (SELECT ws_item_sk FROM web_sales ORDER BY ws_net_profit DESC LIMIT 1)
WHERE 
    cs.total_net_profit > 0
ORDER BY 
    cs.total_net_profit DESC
LIMIT 10;
