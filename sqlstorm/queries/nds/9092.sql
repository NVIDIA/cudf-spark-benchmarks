
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
YearlySales AS (
    SELECT 
        d_year,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS total_transactions
    FROM 
        SalesData
    GROUP BY 
        d_year
),
GenderDemographics AS (
    SELECT 
        cd_gender,
        SUM(ws_sales_price * ws_quantity) AS gender_sales,
        SUM(ws_net_profit) AS gender_profit
    FROM 
        SalesData
    GROUP BY 
        cd_gender
)
SELECT 
    ys.d_year,
    ys.total_sales,
    ys.total_profit,
    gd.gender_sales,
    gd.gender_profit
FROM 
    YearlySales ys
JOIN 
    GenderDemographics gd ON ys.d_year = 2022
ORDER BY 
    ys.total_sales DESC;
