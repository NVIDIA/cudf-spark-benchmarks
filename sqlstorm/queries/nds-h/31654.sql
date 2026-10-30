
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > 10000
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT n.n_name, SUM(od.total_revenue) AS total_nation_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY n.n_name
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_mfgr, p.p_brand, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 500
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_mfgr, p.p_brand
),
SupplierSummary AS (
    SELECT ts.s_suppkey, ts.s_name, SUM(sp.total_availqty) AS total_quantity
    FROM TopSuppliers ts
    LEFT JOIN SupplierParts sp ON ts.s_suppkey = sp.ps_suppkey
    GROUP BY ts.s_suppkey, ts.s_name
)
SELECT 
    nr.n_name,
    COALESCE(nr.total_nation_revenue, 0) AS national_revenue,
    ss.s_name,
    COALESCE(ss.total_quantity, 0) AS supplier_quantity
FROM NationRevenue nr
FULL OUTER JOIN SupplierSummary ss ON (nr.total_nation_revenue > 0 OR ss.total_quantity > 0)
WHERE (nr.total_nation_revenue IS NOT NULL OR ss.total_quantity IS NOT NULL)
ORDER BY nr.n_name, ss.s_name;
