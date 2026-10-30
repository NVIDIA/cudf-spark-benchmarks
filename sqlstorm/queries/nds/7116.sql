
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Num_Orders,
        MAX(d.d_date) AS Last_Purchase_Date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_upper_bound AS Income_Band
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ib.ib_upper_bound
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY Income_Band ORDER BY Total_Sales DESC) AS Sales_Rank
    FROM 
        SalesData
)
SELECT 
    Income_Band,
    COUNT(c_customer_id) AS Number_of_Customers,
    AVG(Total_Sales) AS Avg_Sales,
    MAX(Last_Purchase_Date) AS Most_Recent_Purchase,
    COUNT(CASE WHEN Sales_Rank <= 5 THEN 1 END) AS Top_Customers
FROM 
    RankedSales
GROUP BY 
    Income_Band
ORDER BY 
    Income_Band;
