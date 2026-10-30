
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        d.d_week_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_sold_date_sk,
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        d.d_week_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_profit DESC) AS rank_profit,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS rank_sales
    FROM 
        SalesData
)
SELECT 
    w_warehouse_name,
    d_year,
    d_month_seq,
    d_quarter_seq,
    d_week_seq,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_quantity,
    total_sales,
    total_profit
FROM 
    RankedSales
WHERE 
    rank_profit <= 5 AND rank_sales <= 5
ORDER BY 
    w_warehouse_name, total_profit DESC;
