
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_name, c.c_first_name) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        RankedCustomers rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.ca_state,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    RankedCustomers rc
LEFT JOIN 
    SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    rc.rnk <= 10
ORDER BY 
    rc.ca_state, rc.c_last_name, rc.c_first_name;
