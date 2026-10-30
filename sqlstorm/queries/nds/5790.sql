
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
AggregateSales AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        AVG(order_count) AS avg_orders,
        AVG(total_spent) AS avg_spent
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status, ib_income_band_sk
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.ib_income_band_sk,
    cs.avg_orders,
    cs.avg_spent,
    CASE 
        WHEN cs.avg_spent > 1000 THEN 'High Value'
        WHEN cs.avg_spent > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    AggregateSales AS cs
ORDER BY 
    avg_spent DESC;
