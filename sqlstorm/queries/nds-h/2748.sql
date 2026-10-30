
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
HighValueSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_availqty) FROM partsupp)
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        LAG(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS previous_price
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    r.c_acctbal,
    COALESCE(SUM(fl.l_extendedprice * (1 - fl.l_discount)), 0) AS total_lineitem_value,
    COUNT(DISTINCT h.ps_partkey) AS unique_parts_supplied
FROM RankedOrders r
LEFT JOIN FilteredLineItems fl ON r.o_orderkey = fl.l_orderkey
LEFT JOIN HighValueSuppliers h ON fl.l_partkey = h.ps_partkey
WHERE r.rn = 1
GROUP BY r.o_orderkey, r.o_orderdate, r.c_name, r.c_acctbal
HAVING COALESCE(SUM(fl.l_extendedprice * (1 - fl.l_discount)), 0) > 1000
ORDER BY total_lineitem_value DESC, r.o_orderdate;
