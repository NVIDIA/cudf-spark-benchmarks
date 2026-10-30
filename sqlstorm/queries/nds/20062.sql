
WITH  customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
filtered_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    WHERE 
        ci.rn = 1
        AND (ci.cd_credit_rating = 'Excellent' OR ci.cd_purchase_estimate > 50000)
),
sales_info AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
    GROUP BY 
        ws.ws_bill_customer_sk
),
gross_profit AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        store_sales ss
    WHERE
        ss.ss_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
    GROUP BY 
        ss.ss_customer_sk
),
returns_summary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_value
    FROM 
        store_returns sr
    WHERE 
        sr.sr_customer_sk IN (SELECT c_customer_sk FROM filtered_customers)
    GROUP BY 
        sr.sr_customer_sk
)
SELECT
    fc.c_first_name,
    fc.c_last_name,
    fc.cd_gender,
    fc.cd_marital_status,
    COALESCE(s.total_spent, 0) AS total_spent,
    COALESCE(s.total_orders, 0) AS total_orders,
    COALESCE(gp.total_profit, 0) AS total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_value, 0) AS total_return_value
FROM 
    filtered_customers fc
LEFT JOIN 
    sales_info s ON fc.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    gross_profit gp ON fc.c_customer_sk = gp.ss_customer_sk
LEFT JOIN 
    returns_summary r ON fc.c_customer_sk = r.sr_customer_sk
WHERE 
    (fc.cd_marital_status IS NULL OR fc.cd_marital_status <> 'S')
ORDER BY 
    total_spent DESC, 
    fc.c_last_name ASC;
