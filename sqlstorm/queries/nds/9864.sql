WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        Customer_Sales cs
    WHERE 
        cs.total_sales > 1000
),
Sales_By_Month AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    tc.rank,
    tc.total_sales,
    tc.order_count,
    tc.avg_net_profit,
    sbm.d_year,
    sbm.d_month_seq,
    sbm.monthly_sales
FROM 
    Top_Customers tc
JOIN 
    Sales_By_Month sbm ON tc.c_customer_sk = sbm.d_year % 10  
WHERE 
    tc.rank <= 10 AND sbm.monthly_sales > 5000
ORDER BY 
    tc.rank, sbm.d_year, sbm.d_month_seq;