
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        region r
    JOIN 
        RankedSuppliers rs ON rs.s_suppkey = r.r_regionkey
    WHERE 
        rs.ranking <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.region_name,
    ts.s_name,
    os.total_order_value
FROM 
    TopSuppliers ts
JOIN 
    OrderSummary os ON ts.s_name LIKE '%' || CAST(os.o_orderkey AS STRING) || '%'
ORDER BY 
    ts.region_name, os.total_order_value DESC;
