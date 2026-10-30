WITH SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        dd.d_year,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2000
),
TotalSales AS (
    SELECT 
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        SalesCTE
    WHERE 
        rn = 1
),
Returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns
    FROM 
        (SELECT 
            ws_item_sk, 
            SUM(ws_ext_sales_price) AS total_sales 
        FROM 
            web_sales 
        GROUP BY 
            ws_item_sk) s
    LEFT JOIN 
        Returns r ON s.ws_item_sk = r.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(swr.total_sales, 0) AS item_total_sales,
    swr.total_returns,
    (COALESCE(swr.total_sales, 0) - COALESCE(swr.total_returns, 0)) AS net_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.cd_purchase_estimate >= 10000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 9999 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    item i
LEFT JOIN 
    SalesWithReturns swr ON i.i_item_sk = swr.ws_item_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_id = (SELECT c_customer_id FROM customer LIMIT 1)) 
WHERE 
    i.i_rec_start_date <= cast('2002-10-01' as date) AND 
    (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    net_sales DESC
LIMIT 10;