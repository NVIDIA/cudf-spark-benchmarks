WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        RANK() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 20000 
    GROUP BY 
        ws_bill_customer_sk, ws_ship_mode_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        rs.total_orders,
        rs.total_sales,
        rs.avg_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_city,
    cs.ca_state,
    COUNT(cs.total_orders) AS order_count,
    SUM(cs.total_sales) AS total_revenue,
    AVG(cs.avg_profit) AS avg_profit_per_customer
FROM 
    CustomerSummary cs
WHERE 
    cs.total_orders > 5
GROUP BY 
    cs.c_first_name, cs.c_last_name, cs.ca_city, cs.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 20;