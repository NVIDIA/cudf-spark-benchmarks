
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_item_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
), 
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales_amount,
    cs.order_count,
    cs.unique_item_count,
    d.max_purchase_estimate,
    d.min_purchase_estimate,
    d.avg_purchase_estimate
FROM 
    customer_sales cs
JOIN 
    demographics d ON cs.c_customer_sk = d.cd_demo_sk
ORDER BY 
    cs.total_sales_amount DESC
LIMIT 10;
