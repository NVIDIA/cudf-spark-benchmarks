
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk
), 
weekly_sales AS (
    SELECT 
        d.d_year,
        d.d_week_seq,
        SUM(sd.total_quantity) AS weekly_quantity,
        SUM(sd.total_sales) AS weekly_sales,
        SUM(sd.total_profit) AS weekly_profit
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_week_seq
)
SELECT 
    ws.d_year,
    ws.d_week_seq,
    ws.weekly_quantity,
    ws.weekly_sales,
    ws.weekly_profit,
    RANK() OVER (PARTITION BY ws.d_year ORDER BY ws.weekly_profit DESC) AS profit_rank
FROM 
    weekly_sales ws
WHERE 
    ws.weekly_sales > 10000
ORDER BY 
    ws.d_year, profit_rank;
