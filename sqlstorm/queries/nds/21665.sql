
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),

SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        web_sales ws
    JOIN 
        RankedCustomers rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3))
    GROUP BY 
        ws.ws_item_sk
),

ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    JOIN 
        RankedCustomers rc ON wr.wr_returning_customer_sk = rc.c_customer_sk
    WHERE 
        wr.wr_returned_date_sk IN (SELECT d.d_date_sk 
                                    FROM date_dim d 
                                    WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3))
    GROUP BY 
        wr.wr_item_sk
)

SELECT 
    sd.ws_item_sk,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales_price, 0.00) AS total_sales,
    COALESCE(rd.total_return_quantity, 0) AS total_returned,
    COALESCE(rd.total_return_amt, 0.00) AS total_returned_amt,
    (COALESCE(sd.total_sales_price, 0.00) - COALESCE(rd.total_return_amt, 0.00)) AS net_sales_amount,
    CASE 
        WHEN COALESCE(sd.total_sales_price, 0.00) = 0 THEN NULL
        ELSE (COALESCE(sd.total_sales_price, 0.00) - COALESCE(rd.total_return_amt, 0.00)) / COALESCE(sd.total_sales_price, 1.00) * 100 
    END AS return_percentage
FROM 
    SalesData sd
FULL OUTER JOIN 
    ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
WHERE 
    (COALESCE(sd.total_quantity, 0) > 100 OR COALESCE(rd.total_return_quantity, 0) > 0)
ORDER BY 
    return_percentage DESC NULLS LAST;
