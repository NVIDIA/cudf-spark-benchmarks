
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        ts.s_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.l_partkey,
    SUM(od.l_quantity * od.l_extendedprice) AS total_value,
    COUNT(DISTINCT od.s_name) AS supplier_count
FROM 
    OrderDetails od
GROUP BY 
    od.o_orderkey, 
    od.o_orderdate, 
    od.l_partkey
HAVING 
    SUM(od.l_quantity * od.l_extendedprice) > 10000
ORDER BY 
    total_value DESC;
