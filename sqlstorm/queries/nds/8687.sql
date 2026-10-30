
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458000 AND 2458120 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
PurchaseStats AS (
    SELECT 
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        COUNT(*) AS customer_count,
        AVG(cp.total_spent) AS average_spent,
        AVG(cp.total_orders) AS average_orders
    FROM 
        CustomerPurchases cp
    JOIN 
        customer_demographics cd ON cp.cd_gender = cd.cd_gender AND cp.cd_marital_status = cd.cd_marital_status
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
DateAnalysis AS (
    SELECT 
        d.d_year,
        d.d_quarter_seq,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_quarter_seq
)
SELECT 
    ps.gender,
    ps.marital_status,
    ps.customer_count,
    ps.average_spent,
    da.total_sales,
    da.total_orders
FROM 
    PurchaseStats ps
JOIN 
    DateAnalysis da ON da.d_year = 1999 
ORDER BY 
    ps.customer_count DESC, ps.average_spent DESC;
