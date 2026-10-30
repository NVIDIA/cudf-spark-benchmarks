WITH SalesSummary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459600 AND 2459630  
    GROUP BY 
        ws_bill_cdemo_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ib_income_band_sk
    FROM 
        customer_demographics
    JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
    LEFT JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
),
CustomerSales AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        SUM(ss.total_sales) AS total_sales,
        SUM(ss.total_net_revenue) AS total_net_revenue,
        COUNT(ss.order_count) AS total_orders
    FROM 
        SalesSummary ss
    JOIN 
        Demographics d ON ss.ws_bill_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        d.cd_gender, d.cd_marital_status, d.cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    AVG(total_sales) AS avg_sales,
    AVG(total_net_revenue) AS avg_net_revenue,
    AVG(total_orders) AS avg_orders
FROM 
    CustomerSales
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    avg_sales DESC, avg_net_revenue DESC;