
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
), sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), return_data AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS total_returned_orders
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.ca_city,
    cd.ca_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_returned_orders, 0) AS total_returned_orders,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_revenue
FROM 
    customer_data cd
LEFT JOIN 
    sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    return_data rd ON cd.c_customer_sk = rd.wr_returning_customer_sk
WHERE 
    cd.cd_purchase_estimate > 10000
ORDER BY 
    net_revenue DESC
LIMIT 100;
