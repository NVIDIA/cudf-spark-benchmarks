
WITH Address_Stats AS (
    SELECT 
        ca_city,
        COUNT(*) AS Total_Addresses,
        AVG(LENGTH(ca_street_name)) AS Avg_Street_Name_Length,
        COUNT(DISTINCT ca_zip) AS Unique_Zips
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
    GROUP BY 
        ca_city
),
Customer_Stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS Total_Customers,
        AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate,
        SUM(cd_dep_count) AS Total_Dependants
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Sales_Stats AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS Total_Net_Profit,
        AVG(ws_quantity) AS Avg_Sold_Quantity
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.Total_Addresses,
    a.Avg_Street_Name_Length,
    a.Unique_Zips,
    c.cd_gender,
    c.Total_Customers,
    c.Avg_Purchase_Estimate,
    c.Total_Dependants,
    s.d_year,
    s.Total_Net_Profit,
    s.Avg_Sold_Quantity
FROM 
    Address_Stats a
JOIN 
    Customer_Stats c ON a.Total_Addresses > 100
JOIN 
    Sales_Stats s ON s.Total_Net_Profit > 50000
ORDER BY 
    a.Total_Addresses DESC, 
    s.Total_Net_Profit DESC;
