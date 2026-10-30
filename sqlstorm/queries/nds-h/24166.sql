
WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l.l_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_suppkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        n.n_name, 
        s.s_suppkey, 
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name, n.n_name, s.s_suppkey, s.s_name
),
NullLogicTest AS (
    SELECT 
        t.s_suppkey,
        t.s_name,
        CASE 
            WHEN t.total_supplycost IS NULL THEN 'No Supply Costs'
            WHEN t.total_supplycost > 5000 THEN 'High Cost Supplier'
            ELSE 'Standard Supplier'
        END AS supplier_category
    FROM 
        TopSuppliers t
    WHERE 
        t.total_supplycost IS NULL OR t.total_supplycost > 1000
)

SELECT 
    cs.c_name,
    cs.c_acctbal,
    COALESCE(rs.total_sales, 0) AS total_sales,
    n.n_name,
    n.n_comment,
    nt.supplier_category
FROM 
    customer cs 
LEFT JOIN 
    (SELECT 
         o.o_custkey,
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales 
     FROM 
         orders o
     JOIN 
         lineitem l ON o.o_orderkey = l.l_orderkey
     WHERE 
         o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
     GROUP BY 
         o.o_custkey) rs ON cs.c_custkey = rs.o_custkey
JOIN 
    nation n ON cs.c_nationkey = n.n_nationkey
JOIN 
    NullLogicTest nt ON n.n_nationkey = nt.s_suppkey
ORDER BY 
    cs.c_name
LIMIT 100 OFFSET 10;
