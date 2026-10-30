
WITH CustomerReturns AS (
    SELECT 
        cr_returned_date_sk, 
        COUNT(DISTINCT cr_returning_customer_sk) AS unique_customers, 
        SUM(cr_return_amount) AS total_return_amount, 
        SUM(cr_return_quantity) AS total_return_quantity 
    FROM 
        catalog_returns 
    WHERE 
        cr_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50)
    GROUP BY 
        cr_returned_date_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_net_profit) AS total_net_profit, 
        SUM(ws_quantity) AS total_quantity_sold 
    FROM 
        web_sales 
    WHERE 
        ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandA')
    GROUP BY 
        ws_sold_date_sk
),
ReturnSalesComparison AS (
    SELECT 
        d.d_date AS date, 
        COALESCE(cr.unique_customers, 0) AS unique_customers_returning, 
        COALESCE(cr.total_return_amount, 0) AS total_return_value, 
        COALESCE(sd.total_net_profit, 0) AS total_net_profit, 
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold 
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns cr ON d.d_date_sk = cr.cr_returned_date_sk
    LEFT JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy IN (1, 2)
)
SELECT 
    rsc.date,
    rsc.unique_customers_returning,
    rsc.total_return_value,
    rsc.total_net_profit,
    rsc.total_quantity_sold,
    (rsc.total_net_profit - rsc.total_return_value) AS net_result
FROM 
    ReturnSalesComparison rsc
ORDER BY 
    rsc.date;
