WITH SupplierCost AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, s.s_name, s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrderStats c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, SC.ps_supplycost
    FROM part p
    LEFT JOIN SupplierCost SC ON p.p_partkey = SC.ps_partkey
    WHERE SC.rn = 1
)
SELECT 
    n.n_name AS nation,
    ps.p_brand,
    SUM(COALESCE(li.l_extendedprice, 0)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT cu.c_custkey) AS high_value_customers
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN customer cu ON o.o_custkey = cu.c_custkey
JOIN nation n ON cu.c_nationkey = n.n_nationkey
JOIN PartSupplierDetails ps ON li.l_partkey = ps.p_partkey
WHERE li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
AND li.l_returnflag = 'N'
AND EXISTS (SELECT 1 FROM HighValueCustomers hvc WHERE hvc.c_custkey = cu.c_custkey)
GROUP BY n.n_name, ps.p_brand
ORDER BY total_revenue DESC;