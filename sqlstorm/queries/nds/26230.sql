
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_email_address LIKE '%@example.com%'
),
CustomerAddresses AS (
    SELECT 
        rc.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        RankedCustomers rc
    JOIN 
        customer_address ca ON rc.c_customer_sk = ca.ca_address_sk
    WHERE 
        rc.customer_rank <= 10
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ca.c_customer_sk,
    ca.full_address,
    rs.total_sales
FROM 
    CustomerAddresses ca
LEFT JOIN 
    RecentSales rs ON ca.c_customer_sk = rs.ws_bill_customer_sk
ORDER BY 
    rs.total_sales DESC NULLS LAST;
