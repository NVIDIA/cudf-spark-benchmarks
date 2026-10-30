
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01' 
        AND l.l_shipdate > '1997-01-01'
    GROUP BY 
        r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        supplier_cost DESC
    LIMIT 5
)
SELECT 
    rs.region_name,
    rs.total_sales,
    ts.supplier_name,
    ts.supplier_cost
FROM 
    RegionalSales rs
CROSS JOIN 
    TopSuppliers ts
ORDER BY 
    rs.total_sales DESC, ts.supplier_cost DESC;
