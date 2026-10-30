
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
),
AggregatedSales AS (
    SELECT 
        d_year,
        d_month_seq,
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_transactions,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, cd_gender, cd_marital_status
)
SELECT 
    d_year,
    d_month_seq,
    cd_gender,
    cd_marital_status,
    total_transactions,
    total_sales,
    avg_net_paid
FROM 
    AggregatedSales
WHERE 
    total_sales > 100000
ORDER BY 
    d_year ASC, d_month_seq ASC, total_sales DESC;
