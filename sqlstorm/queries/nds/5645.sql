
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        dd.d_year,
        dd.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
),
AggregatedSales AS (
    SELECT 
        c_customer_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_spent,
        MAX(d_year) AS last_purchase_year,
        MAX(d_month_seq) AS last_purchase_month,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        SalesData
    GROUP BY 
        c_customer_id, cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    AVG(total_quantity) AS avg_quantity,
    AVG(total_spent) AS avg_spent,
    COUNT(c_customer_id) AS customer_count
FROM 
    AggregatedSales
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    avg_spent DESC
LIMIT 10;
