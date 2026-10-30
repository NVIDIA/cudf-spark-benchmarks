WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
    ORDER BY total_cost DESC
    LIMIT 5
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
FilteredCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c 
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
)
SELECT 
    pd.p_name,
    sd.s_name,
    COALESCE(ro.total_revenue, 0) AS total_revenue,
    fc.c_name,
    ROW_NUMBER() OVER (PARTITION BY pd.p_partkey ORDER BY COALESCE(ro.total_revenue, 0) DESC) as revenue_rank
FROM part pd
LEFT JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
LEFT JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN RecentOrders ro ON ro.o_orderkey = ps.ps_partkey
JOIN FilteredCustomer fc ON fc.c_custkey = ro.o_orderkey
WHERE pd.p_retailprice > (
    SELECT AVG(p_retailprice) FROM part
) OR sd.nation IN (SELECT r_name FROM region WHERE r_comment LIKE '%East%')
ORDER BY revenue_rank, total_revenue DESC;