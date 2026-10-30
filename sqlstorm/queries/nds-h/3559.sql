WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1995-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
NationCustomer AS (
    SELECT 
        n.n_name AS nation_name,
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderstatus,
    ro.o_totalprice,
    sp.p_name,
    sp.s_name,
    sp.ps_availqty,
    sp.profit_margin,
    nc.nation_name,
    nc.c_name,
    nc.c_acctbal
FROM RankedOrders ro
LEFT JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey = l.l_partkey
LEFT JOIN NationCustomer nc ON nc.c_custkey = ro.o_orderkey
WHERE sp.profit_margin > 10 AND nc.customer_rank <= 5
ORDER BY ro.o_totalprice DESC, sp.profit_margin ASC;