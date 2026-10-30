WITH  CustomerOrders AS (
    SELECT DISTINCT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_brand
), HighValueCustomers AS (
   SELECT c.c_custkey, c.c_name, c.c_acctbal 
   FROM customer c
   WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), ExcludedNations AS (
    SELECT DISTINCT n.n_nationkey
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Africa%')
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    s.s_name AS supplier_name,
    ps.ps_supplycost,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS customer_rank
FROM CustomerOrders co
LEFT JOIN partsupp ps ON co.c_custkey = ps.ps_suppkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
WHERE co.c_custkey NOT IN (SELECT n.n_nationkey FROM ExcludedNations n)
ORDER BY co.total_spent DESC, co.c_custkey;
