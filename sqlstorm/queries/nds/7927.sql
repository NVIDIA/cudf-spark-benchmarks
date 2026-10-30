
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_credit_rating = 'High'
        AND cd.cd_purchase_estimate > 5000
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)

SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.total_net_profit,
    cs.total_quantity_sold,
    SUM(wa.w_warehouse_sq_ft) AS total_warehouse_space
FROM 
    CustomerStats cs
JOIN 
    warehouse wa ON wa.w_warehouse_sk IN (
        SELECT DISTINCT ws.ws_warehouse_sk
        FROM web_sales ws
        JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE c.c_first_shipto_date_sk IS NOT NULL
    )
GROUP BY 
    cs.cd_gender, 
    cs.cd_marital_status,
    cs.customer_count,
    cs.total_net_profit,
    cs.total_quantity_sold
ORDER BY 
    total_net_profit DESC, 
    customer_count DESC;
