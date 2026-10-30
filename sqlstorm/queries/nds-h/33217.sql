WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesCTE
)
SELECT 
    p.p_partkey,
    p.p_name,
    ns.n_name,
    rs.total_sales,
    rs.o_orderdate,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY rs.total_sales DESC) AS nation_rank,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exists'
    END AS sales_status
FROM 
    RankedSales rs
JOIN 
    partsupp ps ON rs.o_orderkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    NationSupplier ns ON p.p_mfgr = ns.n_name
WHERE 
    rs.total_sales > 10000
    AND p.p_size BETWEEN 10 AND 20
ORDER BY 
    ns.n_name, rs.total_sales DESC
LIMIT 50;
