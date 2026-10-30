
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(addr.full_address, 'Unknown Address') AS address,
        addr.ca_city,
        addr.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        AddressDetails addr ON c.c_current_addr_sk = addr.ca_address_sk
),
DateFilter AS (
    SELECT 
        d_date_sk
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
SalesStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM DateFilter)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cs.customer_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_orders,
    ss.total_profit,
    cs.address,
    cs.ca_city,
    cs.ca_state
FROM 
    CustomerStats cs
JOIN 
    SalesStatistics ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    cs.cd_purchase_estimate > 50000
ORDER BY 
    ss.total_profit DESC, cs.customer_name ASC;
