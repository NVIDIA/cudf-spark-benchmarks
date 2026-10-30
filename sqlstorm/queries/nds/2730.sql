
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS total_warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
ReturnStats AS (
    SELECT 
        COUNT(*) AS total_returns,
        SUM(ws.ws_net_paid_inc_tax) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_order_number = ws.ws_order_number
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.avg_order_value,
    ss.unique_customers,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    ws.total_warehouse_sales,
    rs.total_returns,
    rs.total_returned_amount
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerDemographics cd ON ss.unique_customers = cd.customer_count
JOIN 
    WarehouseSales ws ON 1=1
CROSS JOIN 
    ReturnStats rs
ORDER BY 
    ss.d_year DESC, ss.total_sales DESC;
