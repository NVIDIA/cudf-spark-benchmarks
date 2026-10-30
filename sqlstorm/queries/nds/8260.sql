
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        CAST(d.d_date AS DATE) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        w.w_warehouse_name, CAST(d.d_date AS DATE)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS customer_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
PerformanceMetrics AS (
    SELECT 
        sd.sales_date,
        sd.w_warehouse_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(sd.total_sales) AS warehouse_sales,
        COUNT(DISTINCT ci.c_customer_id) AS distinct_customers,
        SUM(ci.customer_sales) AS customer_contribution
    FROM 
        SalesData sd
    JOIN 
        CustomerInfo ci ON sd.sales_date = CAST('2002-10-01' AS DATE)
    GROUP BY 
        sd.sales_date, sd.w_warehouse_name, ci.cd_gender, ci.cd_marital_status
)
SELECT 
    w_warehouse_name AS warehouse_name,
    cd_gender,
    cd_marital_status,
    AVG(distinct_customers) AS avg_distinct_customers,
    SUM(customer_contribution) AS total_customer_contribution,
    SUM(warehouse_sales) AS total_warehouse_sales
FROM 
    PerformanceMetrics
GROUP BY 
    w_warehouse_name, cd_gender, cd_marital_status
ORDER BY 
    total_warehouse_sales DESC, avg_distinct_customers DESC;
