
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.w_warehouse_id,
    ss.total_quantity_sold,
    ss.total_sales,
    ss.avg_profit,
    cd.cd_gender,
    cd.customer_count,
    cd.total_profit 
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cd ON cd.total_profit IS NOT NULL
ORDER BY 
    ss.total_sales DESC, 
    cd.total_profit DESC;
