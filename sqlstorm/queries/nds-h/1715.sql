WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
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
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS number_of_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RegionNation AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        n.n_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(COALESCE(ss.total_supply_cost, 0)) AS total_supply_cost,
    SUM(COALESCE(od.total_price, 0)) AS total_order_price,
    AVG(od.number_of_items) AS avg_items_per_order,
    AVG(ss.unique_parts) AS avg_unique_parts_per_supplier
FROM 
    RegionNation r
LEFT JOIN 
    supplier s ON s.s_nationkey = r.n_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderDetails od ON s.s_suppkey = od.o_orderkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY 
    total_order_price DESC, avg_unique_parts_per_supplier DESC;