WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    fs.s_name,
    fs.total_cost,
    co.c_name,
    SUM(co.o_totalprice) AS total_order_value,
    COUNT(co.o_orderkey) AS number_of_orders
FROM 
    FilteredSuppliers fs
JOIN 
    lineitem l ON fs.s_suppkey = l.l_suppkey
JOIN 
    CustomerOrders co ON l.l_orderkey = co.o_orderkey
GROUP BY 
    fs.s_name, fs.total_cost, co.c_name
ORDER BY 
    total_order_value DESC, fs.s_name;
