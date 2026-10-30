
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid_inc_tax,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CAST('2002-10-01' AS DATE))
),
ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.ws_quantity,
        sd.ws_sales_price,
        sd.ws_net_paid_inc_tax,
        rd.total_returns,
        rd.total_return_amt
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        sd.rank = 1
)
SELECT 
    cd.ws_item_sk,
    COUNT(cd.ws_order_number) AS total_orders,
    SUM(cd.ws_quantity) AS total_quantity_sold,
    SUM(cd.ws_sales_price * cd.ws_quantity) AS total_sales,
    COALESCE(SUM(cd.total_returns), 0) AS total_returns,
    COALESCE(SUM(cd.total_return_amt), 0) AS total_return_amt,
    SUM(cd.ws_net_paid_inc_tax) AS total_net_paid
FROM 
    CombinedData cd
GROUP BY 
    cd.ws_item_sk
HAVING 
    SUM(cd.ws_sales_price * cd.ws_quantity) > 5000
ORDER BY 
    total_sales DESC;
