WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_value,
        ss.parts_count
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_value > (SELECT AVG(total_value) FROM SupplierStats)
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
)

SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_totalprice,
    hs.s_suppkey,
    hs.s_name,
    hs.total_value,
    hs.parts_count
FROM 
    CustomerOrders co
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    HighValueSuppliers hs ON ps.ps_suppkey = hs.s_suppkey
WHERE 
    li.l_returnflag = 'N' 
ORDER BY 
    co.o_totalprice DESC, hs.total_value DESC;