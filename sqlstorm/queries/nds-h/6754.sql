WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_sales
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.nation,
        total_sales,
        RANK() OVER (PARTITION BY nation ORDER BY total_sales DESC) as sales_rank
    FROM 
        SupplierSales s
)
SELECT 
    r.nation,
    COUNT(rs.s_suppkey) AS supplier_count,
    AVG(rs.total_sales) AS avg_sales,
    MAX(rs.total_sales) AS max_sales
FROM 
    RankedSuppliers rs
JOIN 
    (SELECT DISTINCT n.n_name AS nation FROM nation n) r 
ON 
    rs.nation = r.nation
WHERE 
    rs.sales_rank <= 3
GROUP BY 
    r.nation
ORDER BY 
    r.nation;
