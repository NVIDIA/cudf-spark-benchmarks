
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(spd.total_supply_value) AS total_value
    FROM SupplierPartDetails spd
    JOIN supplier s ON spd.s_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(spd.total_supply_value) > 1000000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(hvs.total_value, 0) AS supplier_total_value,
    EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = r.o_orderkey
        AND l.l_returnflag = 'R'
    ) AS has_returns_flag
FROM RankedOrders r
LEFT JOIN HighValueSuppliers hvs ON hvs.s_suppkey = (
    SELECT 
        ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_size > 20 
    ORDER BY ps.ps_availqty DESC 
    LIMIT 1
)
WHERE r.rn <= 10 OR hvs.total_value IS NOT NULL
ORDER BY r.o_orderdate DESC, r.o_totalprice ASC;
