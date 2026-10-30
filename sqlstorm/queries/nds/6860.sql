
WITH SalesAnalytics AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, d.d_year
),
AnnualSales AS (
    SELECT 
        d_year,
        SUM(total_sales) AS annual_sales,
        SUM(total_orders) AS annual_orders,
        AVG(avg_net_profit) AS annual_avg_net_profit,
        SUM(unique_items_sold) AS total_unique_items
    FROM 
        SalesAnalytics
    GROUP BY 
        d_year
)
SELECT 
    a.d_year,
    a.annual_sales,
    a.annual_orders,
    a.annual_avg_net_profit,
    a.total_unique_items,
    CASE 
        WHEN a.annual_sales > LAG(a.annual_sales) OVER (ORDER BY a.d_year) THEN 'Increased'
        WHEN a.annual_sales < LAG(a.annual_sales) OVER (ORDER BY a.d_year) THEN 'Decreased'
        ELSE 'Unchanged'
    END AS sales_trend
FROM 
    AnnualSales a
ORDER BY 
    a.d_year;
