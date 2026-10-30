
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022
        )
    GROUP BY 
        ws_bill_customer_sk
), TopCustomers AS (
    SELECT 
        rc.ws_bill_customer_sk,
        rc.total_sales,
        rc.total_orders,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        RankedSales rc
    JOIN 
        customer_demographics cd ON rc.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        rc.sales_rank <= 10
), CustomerAddresses AS (
    SELECT 
        tc.ws_bill_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        TopCustomers tc
    JOIN 
        customer c ON tc.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.ca_country,
    COUNT(tc.ws_bill_customer_sk) AS customer_count,
    SUM(tc.total_sales) AS total_sales,
    AVG(tc.total_orders) AS avg_orders_per_customer
FROM 
    CustomerAddresses a
JOIN 
    TopCustomers tc ON a.ws_bill_customer_sk = tc.ws_bill_customer_sk
GROUP BY 
    a.ca_city, a.ca_state, a.ca_country
ORDER BY 
    total_sales DESC;
