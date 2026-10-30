
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        n.n_name, r.r_name
), HighValueSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 1000
    GROUP BY 
        s.s_name
), TopNations AS (
    SELECT 
        nation_name,
        region_name,
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    t.nation_name,
    t.region_name,
    t.total_sales,
    COALESCE(h.supplier_value, 0) AS high_value_supplier_amount
FROM 
    TopNations t
LEFT JOIN 
    HighValueSuppliers h ON t.nation_name = h.s_name
ORDER BY 
    t.total_sales DESC, t.nation_name;
