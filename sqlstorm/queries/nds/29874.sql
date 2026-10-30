
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnDetails AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_returned,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cd.customer_name,
    ad.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_returned, 0) AS total_returned,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(rd.return_count, 0) AS return_count,
    ROUND(((COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returned, 0)) / NULLIF(COALESCE(sd.total_sales, 0), 0)) * 100, 2) AS return_percentage
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    ReturnDetails rd ON cd.c_customer_sk = rd.wr_returning_customer_sk
ORDER BY 
    return_percentage DESC, 
    cd.customer_name;
