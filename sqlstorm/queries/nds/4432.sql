
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458921 AND 2458980
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT sd.c_customer_id) AS unique_customers,
        MAX(sd.ws_order_number) AS latest_order_number
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_item_sk
),
ReturnedSales AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 2458921 AND 2458980
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales_price,
    ts.unique_customers,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rs.total_returned_amt, 0) AS total_returned_amt,
    (ts.total_sales_price - COALESCE(rs.total_returned_amt, 0)) AS net_sales,
    CASE 
        WHEN ts.total_sales_price > 0 THEN (COALESCE(rs.total_returned_amt, 0) / ts.total_sales_price) * 100
        ELSE 0 
    END AS return_percentage
FROM 
    TopSales ts
LEFT JOIN 
    ReturnedSales rs ON ts.ws_item_sk = rs.wr_item_sk
ORDER BY 
    net_sales DESC
LIMIT 10;
