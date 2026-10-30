
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        dd.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, dd.d_year, dd.d_month_seq
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    rs.c_customer_id,
    rs.total_profit,
    rs.total_orders,
    rs.avg_order_value,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.d_year,
    rs.d_month_seq
FROM 
    RankedSales rs
WHERE 
    rs.profit_rank <= 10
ORDER BY 
    rs.d_year, rs.d_month_seq, rs.total_profit DESC;
