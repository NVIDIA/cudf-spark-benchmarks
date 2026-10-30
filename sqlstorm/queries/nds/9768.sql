
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, d.d_year, d.d_month_seq, d.d_quarter_seq
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS customer_total_net_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
AggregatedData AS (
    SELECT 
        sd.w_warehouse_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.customer_total_net_paid) AS total_customer_spending,
        SUM(sd.total_net_paid) AS warehouse_total_spending
    FROM 
        SalesData sd
    JOIN 
        CustomerData cd ON sd.total_quantity > 0
    GROUP BY 
        sd.w_warehouse_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    w_warehouse_name,
    cd_gender,
    cd_marital_status,
    total_customer_spending,
    warehouse_total_spending
FROM 
    AggregatedData
WHERE 
    total_customer_spending > (SELECT AVG(total_customer_spending) FROM AggregatedData)
ORDER BY 
    warehouse_total_spending DESC, total_customer_spending DESC;
