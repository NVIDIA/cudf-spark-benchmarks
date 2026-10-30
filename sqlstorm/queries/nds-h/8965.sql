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
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        r.r_name
), 
SupplierContribution AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
) 
SELECT 
    rs.region_name,
    rs.total_sales,
    sc.supplier_name,
    sc.supplier_cost
FROM 
    RegionalSales rs
JOIN 
    SupplierContribution sc ON rs.region_name = (SELECT r.r_name FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = 'CustomerName')) 
ORDER BY 
    rs.total_sales DESC, sc.supplier_cost ASC
LIMIT 10;
