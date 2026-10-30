
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_sales DESC) AS sales_rank,
        dt.d_date AS sale_date
    FROM 
        SalesData sd
    JOIN 
        date_dim dt ON sd.ws_sold_date_sk = dt.d_date_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        wr_order_number
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk, wr_order_number
),
CustomerSales AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr_returning_customer_sk) AS returning_customers,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_returns wr
    LEFT JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_sales,
    cr.returning_customers,
    cr.total_profit,
    CASE 
        WHEN cr.returning_customers IS NOT NULL THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status
FROM 
    RankedSales rs
LEFT JOIN 
    CustomerSales cr ON rs.ws_item_sk = cr.wr_item_sk
WHERE 
    rs.sales_rank <= 10
AND 
    rs.sale_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    rs.total_sales DESC;
