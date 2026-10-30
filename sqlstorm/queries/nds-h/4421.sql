WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM orders o
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    r.status_rank,
    c.c_name AS customer_name,
    c.total_order_value,
    c.order_count,
    s.s_name AS supplier_name,
    s.total_supply_cost
FROM RankedOrders r
LEFT JOIN CustomerOrders c ON r.o_orderkey = c.c_custkey 
LEFT JOIN SupplierDetails s ON r.o_orderkey = s.s_suppkey
WHERE r.o_orderstatus IN ('P', 'F')
AND r.o_totalprice > 500
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;
