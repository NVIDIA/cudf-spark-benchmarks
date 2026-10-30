
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_name, d.d_year, d.d_month_seq
), CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        SUM(sd.total_quantity_sold) AS total_quantity,
        SUM(sd.total_sales_amount) AS total_sales,
        AVG(sd.average_net_profit) AS avg_profit
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.total_quantity_sold = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    cd.total_quantity,
    cd.total_sales,
    cd.avg_profit,
    CASE 
        WHEN cd.total_sales > 100000 THEN 'High Performer'
        WHEN cd.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    CustomerDemographics cd
ORDER BY 
    cd.total_sales DESC;
