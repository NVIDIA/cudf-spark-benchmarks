WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk BETWEEN 2459565 AND 2459730 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales_price,
        sd.avg_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
ProductReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales_price,
        COALESCE(pr.total_returns, 0) AS total_returns,
        COALESCE(pr.total_return_amt, 0) AS total_return_amt,
        (ts.total_sales_price - COALESCE(pr.total_return_amt, 0)) AS net_sales
    FROM 
        TopSales ts
    LEFT JOIN 
        ProductReturns pr ON ts.ws_item_sk = pr.wr_item_sk
)
SELECT 
    p.i_item_id,
    p.i_item_desc,
    fr.total_quantity,
    fr.total_sales_price,
    fr.total_returns,
    fr.total_return_amt,
    fr.net_sales
FROM 
    FinalReport fr
JOIN 
    item p ON fr.ws_item_sk = p.i_item_sk
ORDER BY 
    fr.net_sales DESC;