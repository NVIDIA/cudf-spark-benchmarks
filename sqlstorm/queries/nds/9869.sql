
WITH SalesStats AS (
    SELECT 
        d.d_year AS Year,
        d.d_month_seq AS Month,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        SUM(ws.ws_ext_tax) AS TotalTax,
        SUM(ws.ws_net_profit) AS NetProfit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_year, d.d_month_seq
), MonthlyTrend AS (
    SELECT 
        Year,
        Month,
        TotalOrders,
        TotalSales,
        TotalTax,
        NetProfit,
        LAG(TotalSales) OVER (PARTITION BY Year ORDER BY Month) AS PrevMonthSales,
        CASE
            WHEN LAG(TotalSales) OVER (PARTITION BY Year ORDER BY Month) IS NOT NULL THEN 
                ((TotalSales - LAG(TotalSales) OVER (PARTITION BY Year ORDER BY Month)) / LAG(TotalSales) OVER (PARTITION BY Year ORDER BY Month)) * 100
            ELSE NULL
        END AS SalesGrowth
    FROM 
        SalesStats
)
SELECT 
    Year, 
    Month, 
    TotalOrders, 
    TotalSales, 
    TotalTax, 
    NetProfit, 
    PrevMonthSales, 
    SalesGrowth
FROM 
    MonthlyTrend
ORDER BY 
    Year, Month;
