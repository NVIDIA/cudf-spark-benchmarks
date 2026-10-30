
WITH SalesData AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        i_brand,
        cd_gender,
        d_year
    FROM 
        web_sales 
    JOIN 
        item ON ws_item_sk = i_item_sk
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2021 AND 2023 AND
        cd_gender IN ('M', 'F')
    GROUP BY 
        i_brand, cd_gender, d_year
), RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, cd_gender ORDER BY total_sales DESC) AS rank
    FROM 
        SalesData
)
SELECT 
    d_year, 
    cd_gender, 
    i_brand, 
    total_sales, 
    order_count, 
    avg_net_profit
FROM 
    RankedSales
WHERE 
    rank <= 5
ORDER BY 
    d_year, 
    cd_gender, 
    total_sales DESC;
