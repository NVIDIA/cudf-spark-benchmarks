WITH AddressCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    GROUP BY 
        ca_city, ca_state
), 
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), 
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS net_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    AC.ca_city,
    AC.ca_state,
    AC.address_count,
    GS.cd_gender,
    GS.customer_count,
    GS.total_dependencies,
    SS.d_year,
    SS.total_sales,
    SS.net_profit
FROM 
    AddressCounts AC
JOIN 
    GenderStats GS ON AC.ca_state = 'NY'  
JOIN 
    SalesSummary SS ON SS.d_year >= 1998  
ORDER BY 
    AC.address_count DESC, GS.customer_count DESC, SS.total_sales DESC;