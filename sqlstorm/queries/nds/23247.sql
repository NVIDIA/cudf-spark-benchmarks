WITH Seasonal_Sales AS (
    SELECT 
        d.d_year AS sale_year,
        SUM(CASE 
            WHEN d.d_month_seq BETWEEN 1 AND 3 THEN ws_ext_sales_price 
            ELSE 0 END) AS Q1_Sales,
        SUM(CASE 
            WHEN d.d_month_seq BETWEEN 4 AND 6 THEN ws_ext_sales_price 
            ELSE 0 END) AS Q2_Sales,
        SUM(CASE 
            WHEN d.d_month_seq BETWEEN 7 AND 9 THEN ws_ext_sales_price 
            ELSE 0 END) AS Q3_Sales,
        SUM(CASE 
            WHEN d.d_month_seq BETWEEN 10 AND 12 THEN ws_ext_sales_price 
            ELSE 0 END) AS Q4_Sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
Customer_Analytics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        SUM(ws.ws_net_profit) AS Total_Profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS Profit_Rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 5
),
Sales_Comparison AS (
    SELECT 
        sale_year,
        Q1_Sales,
        Q2_Sales,
        Q3_Sales,
        Q4_Sales,
        LEAD(Q1_Sales) OVER (ORDER BY sale_year) AS Next_Q1_Sales,
        LEAD(Q2_Sales) OVER (ORDER BY sale_year) AS Next_Q2_Sales
    FROM 
        Seasonal_Sales
    WHERE 
        Q1_Sales IS NOT NULL OR Q2_Sales IS NOT NULL
)
SELECT 
    ca.c_customer_sk,
    CASE 
        WHEN ca.Total_Profit > 1000 THEN 'Gold'
        WHEN ca.Total_Profit BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze' 
    END AS Customer_Tier,
    sc.sale_year,
    sc.Q1_Sales,
    sc.Q2_Sales,
    sc.Q3_Sales,
    sc.Q4_Sales,
    (COALESCE(sc.Next_Q1_Sales, 0) - sc.Q1_Sales) * 100.0 / NULLIF(sc.Q1_Sales, 0) AS Q1_Growth_Percentage,
    (COALESCE(sc.Next_Q2_Sales, 0) - sc.Q2_Sales) * 100.0 / NULLIF(sc.Q2_Sales, 0) AS Q2_Growth_Percentage
FROM 
    Customer_Analytics ca
LEFT JOIN 
    Sales_Comparison sc ON sc.sale_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 1
WHERE 
    ca.Profit_Rank <= 10
ORDER BY 
    ca.Total_Profit DESC, sc.sale_year;