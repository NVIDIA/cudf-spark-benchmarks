
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.full_name,
        cs.total_sales,
        cs.avg_net_paid,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        cs.c_customer_id
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 10000
),
AddressWithDemographics AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        c.c_customer_id
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    tc.full_name,
    tc.total_sales,
    tc.avg_net_paid,
    awd.ca_city,
    awd.ca_state,
    awd.cd_gender,
    awd.cd_marital_status,
    awd.cd_purchase_estimate
FROM 
    TopCustomers tc
JOIN 
    AddressWithDemographics awd ON tc.c_customer_id = awd.c_customer_id
ORDER BY 
    tc.sales_rank;
