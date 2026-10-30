
WITH  sales_growth AS (
    SELECT
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        d_year
),
customer_segments AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
top_segments AS (
    SELECT 
        cs.cd_demo_sk,
        cs.customer_count,
        cs.avg_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cs.customer_count DESC) AS segment_rank
    FROM 
        customer_segments cs
)
SELECT 
    ws.ws_order_number,
    SUM(ws.ws_net_profit) AS total_net_profit,
    MAX(i.i_current_price) AS max_item_price,
    ca.ca_city,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
    CASE 
        WHEN cs.avg_purchase_estimate > 500 THEN 'High' 
        WHEN cs.avg_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium' 
        ELSE 'Low' 
    END AS purchase_category,
    COALESCE(sm.sm_type, 'Not Specified') AS shipping_type
FROM 
    web_sales ws
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_segments cs ON cs.cd_demo_sk = cd.cd_demo_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ws.ws_order_number, ca.ca_city, cs.avg_purchase_estimate, sm.sm_type
HAVING 
    SUM(ws.ws_net_profit) > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
ORDER BY 
    total_net_profit DESC;
