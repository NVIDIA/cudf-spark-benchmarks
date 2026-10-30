
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.nation
    FROM 
        RankedSuppliers s
    WHERE 
        s.rnk <= 3
),
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        t.s_name AS supplier_name,
        t.nation
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers t ON ps.ps_suppkey = t.s_suppkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
)
SELECT 
    od.nation,
    COUNT(DISTINCT od.o_orderkey) AS order_count,
    SUM(od.l_extendedprice) AS total_revenue,
    AVG(od.l_quantity) AS average_quantity_per_order
FROM 
    OrdersWithDetails od
GROUP BY 
    od.nation
ORDER BY 
    total_revenue DESC;
