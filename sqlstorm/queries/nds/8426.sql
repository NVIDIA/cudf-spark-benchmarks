WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        w.w_warehouse_name, d.d_year, d.d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_sales_by_gender_marital_status
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.unique_customers = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
YearlyComparison AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS yearly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
    SUM(cd.total_sales_by_gender_marital_status) AS total_sales,
    yc.yearly_sales,
    (SUM(cd.total_sales_by_gender_marital_status) / NULLIF(yc.yearly_sales, 0)) * 100 AS sales_percentage_of_year
FROM 
    CustomerDemographics cd
JOIN 
    YearlyComparison yc ON cd.cd_gender IS NOT NULL 
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, yc.yearly_sales
ORDER BY 
    total_sales DESC;