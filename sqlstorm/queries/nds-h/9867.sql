WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name, ps.ps_supplycost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT rnk, s_suppkey, s_name, p_partkey, p_name, ps_supplycost
    FROM RankedSuppliers
    WHERE rnk = 1
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_custkey, c.c_name, c.c_acctbal
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
OrderLineItems AS (
    SELECT lo.l_orderkey, lo.l_quantity, lo.l_extendedprice, lo.l_discount, lo.l_tax, 
           lo.l_shipdate, lo.l_returnflag, lo.l_linestatus
    FROM lineitem lo
    JOIN CustomerOrders co ON lo.l_orderkey = co.o_orderkey
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, 
       ol.l_quantity, ol.l_extendedprice, ol.l_discount, ol.l_tax,
       ts.s_name AS top_supplier_name, ts.ps_supplycost
FROM CustomerOrders co
JOIN OrderLineItems ol ON co.o_orderkey = ol.l_orderkey
JOIN TopSuppliers ts ON ol.l_orderkey = ts.p_partkey
WHERE ol.l_returnflag = 'R' AND ol.l_linestatus = 'O'
ORDER BY co.c_custkey, co.o_orderdate DESC, ol.l_quantity DESC;