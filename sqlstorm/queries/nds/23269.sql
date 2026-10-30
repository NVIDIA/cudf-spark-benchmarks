
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS sales_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN 1 AND 366
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
),
Summary AS (
    SELECT 
        d.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ws.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ws.total_sales_amount, 0) AS total_sales_amount,
        (COALESCE(cr.avg_return_quantity, 0) + COALESCE(ws.avg_sales_price, 0)) AS combined_avg
    FROM 
        Demographics d
    LEFT JOIN 
        CustomerReturns cr ON d.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesData ws ON d.c_customer_sk = ws.customer_sk
)
SELECT 
    s.c_customer_sk,
    s.cd_gender,
    s.cd_marital_status,
    CASE 
        WHEN s.total_returned > 0 THEN 'High Return'
        WHEN s.total_quantity_sold > 100 THEN 'High Sales'
        ELSE 'Low Activity'
    END AS customer_activity_level,
    RANK() OVER (PARTITION BY s.cd_gender ORDER BY s.total_return_amount DESC) AS gender_rank,
    ROW_NUMBER() OVER (ORDER BY s.combined_avg DESC) AS overall_rank
FROM 
    Summary s
WHERE 
    s.cd_purchase_estimate < (
        SELECT 
            AVG(cd_purchase_estimate) 
        FROM 
            Demographics)
  AND s.cd_gender IS NOT NULL
ORDER BY 
    s.cd_gender,
    customer_activity_level,
    overall_rank;
