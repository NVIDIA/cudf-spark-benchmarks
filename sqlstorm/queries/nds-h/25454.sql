WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           CONCAT(s.s_address, ', ', n.n_name) AS full_address,
           s.s_acctbal, 
           s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container
    FROM part p
    WHERE LENGTH(p.p_name) > 10
      AND p.p_retailprice > 100
), 
OrderSummary AS (
    SELECT o.o_custkey, 
           COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT sd.s_name, 
       sd.full_address, 
       pd.p_name, 
       os.total_orders, 
       os.total_spent
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN OrderSummary os ON sd.s_suppkey = os.o_custkey
WHERE os.total_spent > 5000
ORDER BY os.total_spent DESC, sd.s_name ASC;
