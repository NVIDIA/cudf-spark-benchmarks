WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus
    FROM 
        OrderDetails o
    WHERE 
        o.total_price > (SELECT AVG(total_price) FROM OrderDetails)
),
SupplierRegions AS (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    sr.n_regionkey,
    sr.supplier_count,
    ss.s_name,
    ss.total_supply_cost,
    h.o_orderkey,
    h.o_orderstatus
FROM 
    SupplierRegions sr
LEFT JOIN 
    SupplierStats ss ON sr.supplier_count > 10  
LEFT JOIN 
    HighValueOrders h ON ss.s_suppkey = h.o_orderkey 
WHERE 
    ss.total_supply_cost IS NOT NULL
ORDER BY 
    sr.n_regionkey, ss.total_supply_cost DESC;