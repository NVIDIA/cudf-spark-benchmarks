WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458850 AND 2459215 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), SalesSummary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS number_of_customers,
        AVG(cs.total_spent) AS avg_spent,
        SUM(cs.total_orders) AS total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.cd_gender = cd.cd_gender AND cs.cd_marital_status = cd.cd_marital_status
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.number_of_customers,
    ss.avg_spent,
    ss.total_orders,
    RANK() OVER (ORDER BY ss.avg_spent DESC) AS rank
FROM 
    SalesSummary ss
WHERE 
    ss.number_of_customers > 50 
ORDER BY 
    ss.avg_spent DESC;