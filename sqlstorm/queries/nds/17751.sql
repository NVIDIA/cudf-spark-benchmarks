
SELECT c_first_name, c_last_name, cd_gender, cd_marital_status 
FROM customer 
JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
WHERE cd_gender = 'F' AND cd_marital_status = 'M';
