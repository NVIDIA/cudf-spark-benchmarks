
WITH SalesData AS (
    SELECT 
        d.d_month_seq AS month,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND d.d_year = 2023
    GROUP BY 
        d.d_month_seq
),
CustomerSegment AS (
    SELECT 
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_marital_status
)
SELECT 
    sd.month,
    sd.total_net_profit,
    sd.number_of_orders,
    sd.avg_quantity_per_order,
    sd.total_quantity_sold,
    cs.cd_marital_status,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM 
    SalesData sd
JOIN 
    CustomerSegment cs ON cs.customer_count > 100
ORDER BY 
    sd.month;
