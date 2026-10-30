WITH SupplierDetail AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT sd.s_suppkey, sd.s_name, sd.s_acctbal
    FROM SupplierDetail sd
    WHERE sd.rank <= 3
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R'
    GROUP BY o.o_orderkey, o.o_orderdate
),
PartRevenue AS (
    SELECT ps.ps_partkey, SUM(os.total_revenue) AS total_revenue
    FROM PartSupplier ps
    LEFT JOIN OrderSummary os ON ps.ps_partkey = os.o_orderkey
    GROUP BY ps.ps_partkey
),
FinalSelection AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, pr.total_revenue,
           COALESCE(pr.total_revenue, 0) AS adjusted_revenue
    FROM part p
    LEFT JOIN PartRevenue pr ON p.p_partkey = pr.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
RankedParts AS (
    SELECT f.*, 
           RANK() OVER (ORDER BY adjusted_revenue DESC) AS revenue_rank
    FROM FinalSelection f
)
SELECT rp.p_partkey, rp.p_name, rp.p_retailprice, rp.adjusted_revenue, rp.revenue_rank
FROM RankedParts rp
WHERE rp.revenue_rank <= 10
ORDER BY rp.adjusted_revenue DESC;
