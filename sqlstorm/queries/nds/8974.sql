
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_employed_dependents,
        SUM(cd_dep_college_count) AS total_college_dependents
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
), SalesStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid) AS total_paid,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales AS w
    JOIN 
        customer AS c ON c.c_customer_sk = w.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), FinalStats AS (
    SELECT 
        cs.cd_gender,
        cs.total_customers,
        cs.avg_purchase_estimate,
        COALESCE(SUM(ss.total_profit), 0) AS total_profit,
        COALESCE(SUM(ss.total_paid), 0) AS total_paid,
        COALESCE(SUM(ss.order_count), 0) AS total_orders,
        COALESCE(SUM(ss.total_quantity_sold), 0) AS total_quantity_sold
    FROM 
        CustomerStats AS cs
    LEFT JOIN 
        SalesStats AS ss ON cs.total_customers = ss.c_customer_sk
    GROUP BY 
        cs.cd_gender, cs.total_customers, cs.avg_purchase_estimate
)
SELECT 
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    total_profit,
    total_paid,
    total_orders,
    total_quantity_sold
FROM 
    FinalStats
ORDER BY 
    total_profit DESC;
