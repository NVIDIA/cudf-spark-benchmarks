
SELECT 
    CA.ca_address_id AS AddressID,
    CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type) AS FullAddress,
    CONCAT(CU.c_first_name, ' ', CU.c_last_name) AS CustomerName,
    CD.cd_gender AS Gender,
    CD.cd_marital_status AS MaritalStatus,
    D.d_date AS TransactionDate,
    SUM(CS.cs_quantity) AS TotalQuantitySold,
    SUM(CS.cs_ext_sales_price) AS TotalSalesAmount,
    COUNT(DISTINCT CS.cs_order_number) AS TotalOrders,
    CASE 
        WHEN SUM(CS.cs_ext_sales_price) > 1000 THEN 'High Value'
        ELSE 'Regular Value' 
    END AS CustomerValueStatus
FROM 
    customer CU 
JOIN 
    customer_address CA ON CU.c_current_addr_sk = CA.ca_address_sk 
JOIN 
    customer_demographics CD ON CU.c_current_cdemo_sk = CD.cd_demo_sk 
JOIN 
    catalog_sales CS ON CU.c_customer_sk = CS.cs_bill_customer_sk 
JOIN 
    date_dim D ON CS.cs_sold_date_sk = D.d_date_sk 
GROUP BY 
    CA.ca_address_id,
    CA.ca_street_number,
    CA.ca_street_name,
    CA.ca_street_type,
    CU.c_first_name,
    CU.c_last_name,
    CD.cd_gender,
    CD.cd_marital_status,
    D.d_date
HAVING 
    SUM(CS.cs_quantity) > 5
ORDER BY 
    TotalSalesAmount DESC;
