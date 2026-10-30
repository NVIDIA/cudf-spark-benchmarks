
WITH sales_data AS (
    SELECT 
        ds.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    WHERE 
        ds.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        ds.d_year
), 
return_data AS (
    SELECT 
        ds.d_year,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    JOIN 
        date_dim ds ON cr.cr_returned_date_sk = ds.d_date_sk
    WHERE 
        ds.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        ds.d_year
)
SELECT
    sd.d_year,
    sd.total_sales,
    sd.order_count,
    sd.avg_net_profit,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.return_count, 0) AS return_count,
    (sd.total_sales - COALESCE(rd.total_returns, 0)) AS net_sales
FROM 
    sales_data sd
LEFT JOIN 
    return_data rd ON sd.d_year = rd.d_year
ORDER BY 
    sd.d_year;
