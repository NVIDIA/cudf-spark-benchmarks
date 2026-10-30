WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), RankedSuppliers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY nation ORDER BY total_revenue DESC) AS rank
    FROM 
        SupplierOrders
)
SELECT 
    nation,
    s_suppkey,
    s_name,
    order_count,
    total_revenue
FROM 
    RankedSuppliers
WHERE 
    rank <= 5
ORDER BY 
    nation, total_revenue DESC;