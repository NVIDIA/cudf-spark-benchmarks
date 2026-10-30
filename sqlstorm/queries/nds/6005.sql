
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023
        AND c.c_birth_year >= 1980
), SaleSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS num_orders,
        SUM(rs.ws_net_paid) AS total_revenue,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.num_orders,
    ss.total_revenue,
    ss.avg_sales_price,
    c.cd_gender,
    c.cd_marital_status
FROM 
    SaleSummary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
JOIN 
    customer_demographics c ON i.i_item_sk = c.cd_demo_sk
WHERE 
    ss.total_revenue > 10000
ORDER BY 
    ss.total_revenue DESC
LIMIT 10;
