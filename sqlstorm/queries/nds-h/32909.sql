WITH  RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) as rank
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s_nationkey, 
        AVG(s_acctbal) AS avg_acctbal, 
        SUM(CASE WHEN s_comment LIKE '%urgent%' THEN 1 ELSE 0 END) as urgent_count
    FROM supplier
    GROUP BY s_nationkey
),
PartAvailability AS (
    SELECT 
        ps_partkey,
        SUM(ps_availqty) AS total_avail_qty,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount) END), 0) AS total_returned,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    AVG(ss.avg_acctbal) AS avg_supplier_acct_bal,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(pa.total_avail_qty) AS total_qty_available,
    MAX(pa.avg_supply_cost) AS max_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_nationkey = ss.s_nationkey
LEFT JOIN lineitem lo ON s.s_suppkey = lo.l_suppkey
LEFT JOIN orders ro ON lo.l_orderkey = ro.o_orderkey
LEFT JOIN PartAvailability pa ON lo.l_partkey = pa.ps_partkey
LEFT JOIN customer co ON ro.o_custkey = co.c_custkey
WHERE (ro.o_orderstatus = 'F' OR ro.o_orderstatus = 'P')
  AND (co.c_acctbal IS NOT NULL AND co.c_acctbal > 100)
GROUP BY r.r_name
HAVING COUNT(DISTINCT co.c_custkey) > 10
ORDER BY total_orders DESC;