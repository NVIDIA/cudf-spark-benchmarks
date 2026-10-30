
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS Total_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        AVG(ws.ws_net_paid_inc_tax) AS Avg_Sale_Amount,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        c_customer_id,
        Total_Profit,
        Total_Orders,
        Avg_Sale_Amount,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY Total_Profit DESC) AS Profit_Rank
    FROM 
        SalesData
)
SELECT 
    r.c_customer_id,
    r.Total_Profit,
    r.Total_Orders,
    r.Avg_Sale_Amount,
    rd.d_year
FROM 
    RankedSales r
JOIN 
    (SELECT DISTINCT d_year FROM SalesData) rd ON r. Profit_Rank <= 10
ORDER BY 
    rd.d_year, r.Total_Profit DESC;
