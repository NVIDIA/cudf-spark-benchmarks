WITH RankedNations AS (
    SELECT 
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
),
PartSupplierStats AS (
    SELECT 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY o.o_orderkey, c.c_name
)
SELECT 
    rn.n_name,
    rn.region_name,
    COUNT(DISTINCT ods.c_name) AS total_customers,
    SUM(ods.total_order_value) AS total_order_value,
    SUM(p_stats.total_available_qty) AS total_part_available_qty,
    AVG(rn.avg_supplier_acctbal) AS avg_supplier_acct_balance
FROM RankedNations rn
JOIN OrderDetails ods ON rn.n_name = ods.c_name
JOIN PartSupplierStats p_stats ON p_stats.total_supply_value > 1000
GROUP BY rn.n_name, rn.region_name
ORDER BY total_order_value DESC, total_customers ASC
LIMIT 10;