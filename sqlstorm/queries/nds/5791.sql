
WITH SalesData AS (
    SELECT 
        d.d_year AS Sales_Year,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        SUM(ws.ws_net_profit) AS Total_Profit,
        cd.cd_gender AS Customer_Gender,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
        AND cd.cd_marital_status = 'M'
        AND i.i_category_id IN (SELECT i_category_id FROM item WHERE i_brand_id = (SELECT i_brand_id FROM item WHERE i_item_id = 'ITEM007'))
    GROUP BY 
        d.d_year, cd.cd_gender
)
SELECT 
    Sales_Year,
    Customer_Gender,
    Total_Sales,
    Total_Profit,
    Total_Orders,
    RANK() OVER (PARTITION BY Sales_Year ORDER BY Total_Sales DESC) AS Sales_Rank
FROM 
    SalesData
ORDER BY 
    Sales_Year, Sales_Rank;
