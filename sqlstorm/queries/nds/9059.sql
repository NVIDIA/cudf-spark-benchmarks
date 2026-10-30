
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_order_number, cd.cd_gender, cd.cd_marital_status, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_month_seq ORDER BY total_profit DESC) AS rank_profit
    FROM 
        SalesData
)
SELECT 
    d_month_seq,
    cd_gender,
    cd_marital_status,
    COUNT(ws_order_number) AS number_of_orders,
    SUM(total_quantity) AS total_quantity,
    SUM(total_profit) AS total_profit
FROM 
    RankedSales
WHERE 
    rank_profit <= 10
GROUP BY 
    d_month_seq, cd_gender, cd_marital_status
ORDER BY 
    d_month_seq, total_profit DESC;
