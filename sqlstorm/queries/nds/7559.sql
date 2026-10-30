
WITH SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        d_year,
        w_state
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        d_year, w_state
), DemographicsData AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    sd.d_year,
    sd.w_state,
    sd.total_sales,
    sd.order_count,
    sd.avg_net_profit,
    dd.customer_count,
    dd.cd_gender,
    dd.cd_marital_status
FROM 
    SalesData sd
JOIN 
    DemographicsData dd ON sd.d_year = (SELECT MAX(d_year) FROM SalesData)
ORDER BY 
    sd.total_sales DESC, dd.customer_count DESC
LIMIT 10;
