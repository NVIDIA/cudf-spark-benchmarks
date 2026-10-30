WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT l.l_orderkey) > 10
),
SupplierRegionSales AS (
    SELECT 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.total_sales,
    ps.p_name,
    ps.order_count,
    s.s_name AS top_supplier
FROM 
    SupplierRegionSales r
JOIN 
    PopularParts ps ON r.r_name = ps.p_name
JOIN 
    RankedSuppliers s ON s.rank = 1 AND s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY 
    r.total_sales DESC;