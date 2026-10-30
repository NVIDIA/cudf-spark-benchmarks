
SELECT 
    c.c_first_name AS CustomerFirstName, 
    c.c_last_name AS CustomerLastName, 
    ca.ca_city AS CustomerCity, 
    ca.ca_state AS CustomerState, 
    cd.cd_gender AS CustomerGender, 
    cd.cd_marital_status AS MaritalStatus,
    COUNT(ws.ws_order_number) AS TotalWebOrders,
    SUM(ws.ws_ext_sales_price) AS TotalWebSales,
    AVG(ws.ws_quantity) AS AverageQuantityPerOrder,
    SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS EmailDomain,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS FullStreetAddress,
    CAST(d.d_date AS DATE) AS SalesDate
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status,
    SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1),
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type),
    CAST(d.d_date AS DATE)
ORDER BY 
    TotalWebSales DESC
LIMIT 100;
