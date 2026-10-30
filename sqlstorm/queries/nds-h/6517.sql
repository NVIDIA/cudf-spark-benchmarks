
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        o.o_orderdate,
        ts.region_name,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, ts.region_name
)
SELECT 
    region_name,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    AVG(order_value) AS avg_order_value,
    SUM(distinct_suppliers) AS total_distinct_suppliers
FROM 
    OrderDetails
GROUP BY 
    region_name
ORDER BY 
    total_orders DESC, avg_order_value DESC;
