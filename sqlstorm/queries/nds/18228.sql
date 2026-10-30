
SELECT COUNT(*) AS total_customers, AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM customer
JOIN customer_demographics ON c_customer_sk = cd_demo_sk
WHERE cd_gender = 'F' AND cd_marital_status = 'M';
