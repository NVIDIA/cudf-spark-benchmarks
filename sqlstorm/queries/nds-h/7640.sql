WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_cost,
        ss.unique_parts_supplied,
        RANK() OVER (ORDER BY ss.total_cost DESC) AS rank_by_cost,
        RANK() OVER (ORDER BY ss.unique_parts_supplied DESC) AS rank_by_parts
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
      AND o.o_orderdate >= DATE '1996-01-01'
),
JoinedData AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        ts.s_suppkey,
        ts.s_name,
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM CustomerOrders co
    JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
)
SELECT 
    jd.c_custkey,
    jd.c_name,
    COUNT(DISTINCT jd.l_orderkey) AS total_orders,
    SUM(jd.l_extendedprice) AS total_extended_price,
    AVG(jd.l_discount) AS average_discount
FROM JoinedData jd
GROUP BY jd.c_custkey, jd.c_name
ORDER BY total_orders DESC, total_extended_price DESC
LIMIT 10;