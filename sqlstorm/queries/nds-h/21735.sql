
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
), SupplierStatistics AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
), NationalAverage AS (
    SELECT 
        n.n_nationkey,
        AVG(s.s_acctbal) AS avg_balance
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice ELSE 0 END) AS total_returns,
    AVG(os.o_totalprice) AS avg_order_value,
    MAX(ss.total_cost) AS max_supplier_cost,
    MIN(ss.part_count) AS min_parts_supplied
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey 
LEFT JOIN orders os ON c.c_custkey = os.o_custkey 
LEFT JOIN lineitem lo ON os.o_orderkey = lo.l_orderkey 
LEFT JOIN SupplierStatistics ss ON ss.ps_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 30)
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
WHERE (c.c_acctbal > (SELECT AVG(avg_balance) FROM NationalAverage) OR c.c_acctbal IS NULL)
    AND (os.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31' OR os.o_orderdate IS NULL)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY r.r_name, n.n_name;
