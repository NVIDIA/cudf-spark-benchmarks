
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk
), ReturnData AS (
    SELECT 
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_returns,
        COUNT(cr_order_number) AS total_return_orders
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr_returned_date_sk
), CombinedData AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales,
        sd.total_orders,
        rd.total_return_orders
    FROM 
        date_dim d
    LEFT JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    LEFT JOIN 
        ReturnData rd ON d.d_date_sk = rd.cr_returned_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    cd.d_date,
    cd.total_sales,
    cd.total_returns,
    cd.net_sales,
    cd.total_orders,
    cd.total_return_orders,
    CASE 
        WHEN cd.total_sales > 0 THEN (cd.total_returns * 100.0 / cd.total_sales)
        ELSE NULL
    END AS return_percentage
FROM 
    CombinedData cd
ORDER BY 
    cd.d_date;
