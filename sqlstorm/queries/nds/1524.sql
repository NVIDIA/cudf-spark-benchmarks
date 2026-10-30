
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
),
ReturnData AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesWithReturns AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_quantity,
        sd.ws_sales_price,
        sd.ws_net_paid,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        cd.customer_count,
        cd.avg_purchase_estimate
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_order_number = rd.wr_order_number
    LEFT JOIN 
        customer c ON sd.ws_item_sk = c.c_customer_sk
    LEFT JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    s.ws_order_number,
    s.ws_item_sk,
    s.ws_quantity,
    s.ws_sales_price,
    s.ws_net_paid,
    s.total_returned,
    s.total_return_amt,
    s.customer_count,
    s.avg_purchase_estimate,
    CASE 
        WHEN s.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    SalesWithReturns s
WHERE 
    s.ws_net_paid > (SELECT AVG(ws_net_paid) FROM SalesWithReturns)
ORDER BY 
    s.ws_order_number;
