
SELECT COUNT(*) AS total_customers, AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM customer_demographics
WHERE cd_gender = 'F' AND cd_marital_status = 'M';
