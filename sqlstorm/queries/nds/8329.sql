
WITH MonthlySales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    m.d_year,
    m.d_month_seq,
    m.total_sales,
    m.total_profit,
    cd.cd_gender,
    cd.customer_count,
    cd.total_dependents,
    ws.warehouse_sales
FROM 
    MonthlySales m
JOIN 
    CustomerDemographics cd ON cd.customer_count > 0
JOIN 
    WarehouseSales ws ON ws.warehouse_sales > 0
ORDER BY 
    m.d_year, m.d_month_seq, ws.warehouse_sales DESC;
