
WITH CustomerStats AS (
    SELECT 
        ca_state,
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(cd_dep_count) AS total_dependent_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state, cd_gender
), 
SalesStats AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_cdemo_sk
), 
FinalStats AS (
    SELECT 
        cs.ca_state,
        cs.cd_gender,
        cs.total_customers,
        cs.total_dependent_count,
        cs.avg_purchase_estimate,
        ss.total_sales,
        ss.total_profit
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesStats ss ON cs.total_customers = ss.ws_bill_cdemo_sk
)
SELECT 
    ca_state,
    cd_gender,
    total_customers,
    total_dependent_count,
    avg_purchase_estimate,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_profit, 0) AS total_profit
FROM 
    FinalStats
ORDER BY 
    ca_state, cd_gender;
