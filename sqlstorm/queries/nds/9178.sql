
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ds.d_year,
        ds.d_month_seq,
        ds.d_quarter_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ds.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ws.ws_sold_date_sk, 
        ds.d_year, 
        ds.d_month_seq,
        ds.d_quarter_seq, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
RankedSales AS (
    SELECT 
        d_year,
        d_quarter_seq,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_profit,
        RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    d_quarter_seq,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_profit
FROM 
    RankedSales
WHERE 
    profit_rank <= 10
ORDER BY 
    d_year,
    d_quarter_seq,
    total_profit DESC;
