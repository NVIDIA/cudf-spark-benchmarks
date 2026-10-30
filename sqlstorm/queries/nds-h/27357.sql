WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           SUBSTR(s.s_phone, 1, 3) AS phone_area_code, 
           s.s_acctbal, 
           s.s_comment 
    FROM supplier s
), 
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_container, 
           p.p_size, 
           p.p_retailprice, 
           p.p_comment 
    FROM part p 
    WHERE p.p_size > 10
), 
JoinDetails AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           pd.p_name, 
           pd.p_brand, 
           sd.s_name AS supplier_name, 
           sd.phone_area_code, 
           sd.s_acctbal
    FROM partsupp ps 
    JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey 
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
), 
FinalResults AS (
    SELECT j.p_name, 
           j.supplier_name, 
           j.phone_area_code, 
           j.ps_availqty, 
           j.ps_supplycost, 
           j.s_acctbal, 
           (j.ps_supplycost * 1.2) AS inflated_cost,
           CASE 
               WHEN j.ps_availqty < 50 THEN 'Low Stock'
               WHEN j.ps_availqty BETWEEN 50 AND 100 THEN 'Moderate Stock'
               ELSE 'High Stock' 
           END AS stock_status 
    FROM JoinDetails j 
    WHERE j.s_acctbal > 1000.00
)
SELECT fr.p_name, 
       fr.supplier_name, 
       fr.phone_area_code, 
       fr.ps_availqty, 
       fr.ps_supplycost, 
       fr.inflated_cost, 
       fr.stock_status 
FROM FinalResults fr 
ORDER BY fr.inflated_cost DESC, fr.p_name ASC 
LIMIT 20;
